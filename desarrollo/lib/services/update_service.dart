import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String? apkDownloadUrl;
  final String releaseUrl;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.changelog,
    this.apkDownloadUrl,
    required this.releaseUrl,
  });
}

class UpdateService {
  static const String currentVersion = 'v1.0.6';
  static const String repoOwner = 'AngelGuevara04';
  static const String repoName = 'lector-mangas';
  static const MethodChannel _channel = MethodChannel('com.amors.reader/updater');

  static const String releasesApiUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static const String issuesUrl =
      'https://github.com/$repoOwner/$repoName/issues/new';

  /// Consulta en segundo plano si existe una versión más reciente en GitHub Releases
  static Future<UpdateInfo> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(releasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'AppParaMiAmors',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String? ?? '';
        final body = data['body'] as String? ?? 'Sin notas de versión.';
        final htmlUrl = data['html_url'] as String? ??
            'https://github.com/$repoOwner/$repoName/releases';

        String? apkUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        final hasUpdate = _isNewerVersion(currentVersion, tagName);

        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: tagName.isNotEmpty ? tagName : currentVersion,
          changelog: body,
          apkDownloadUrl: apkUrl ?? htmlUrl,
          releaseUrl: htmlUrl,
        );
      }
    } catch (_) {
      // Si no hay red no bloqueamos la app
    }

    return const UpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      changelog: '',
      releaseUrl: 'https://github.com/$repoOwner/$repoName/releases',
    );
  }

  /// Descarga el APK directamente dentro de la aplicación con seguimiento en vivo
  static Future<File?> downloadApk(
    String downloadUrl, {
    required Function(double progress, String status) onProgress,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      request.headers['User-Agent'] = 'AppParaMiAmors';
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Error en descarga: código ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/AppParaMiAmors_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();
      int downloadedBytes = 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (contentLength > 0) {
          final progress = downloadedBytes / contentLength;
          final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (contentLength / (1024 * 1024)).toStringAsFixed(1);
          onProgress(progress, '$mbDownloaded MB / $mbTotal MB (${(progress * 100).toInt()}%)');
        } else {
          final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          onProgress(-1.0, '$mbDownloaded MB descargados...');
        }
      }

      await sink.flush();
      await sink.close();
      return apkFile;
    } catch (e) {
      debugPrint('Error al descargar APK: $e');
      return null;
    }
  }

  /// Lanza el instalador nativo de Android para instalar el APK descargado
  static Future<bool> installApk(File apkFile) async {
    try {
      final result = await _channel.invokeMethod<bool>('installApk', {
        'filePath': apkFile.path,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Error al invocar instalador: $e');
      // Si falla el canal nativo, abrir con el sistema
      return await openUrl(apkFile.path);
    }
  }

  /// Compara dos strings de versión semántica (e.g. v1.0.3 vs v1.0.4)
  static bool _isNewerVersion(String current, String remote) {
    if (remote.isEmpty) return false;
    final curClean = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final remClean = remote.replaceAll(RegExp(r'[^0-9.]'), '');

    final curParts = curClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final remParts = remClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final c = i < curParts.length ? curParts[i] : 0;
      final r = i < remParts.length ? remParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Abre un enlace externo en el navegador del teléfono
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Genera y abre el enlace prellenado para una nueva solicitud de mejora en GitHub
  static Future<bool> openFeatureRequest({
    required String title,
    required String description,
    required String category,
  }) async {
    final body = '''
### 💡 Solicitud de Mejora o Reporte

* **Tipo:** $category
* **Versión de la App:** $currentVersion

#### Descripción:
$description

---
*Enviado desde AppParaMiAmors Mobile*
''';

    final uri = Uri.parse(issuesUrl).replace(
      queryParameters: {
        'title': '[$category] $title',
        'body': body,
      },
    );

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Genera y abre un reporte de capítulo caído directo a GitHub Issues
  static Future<bool> openChapterReport({
    required String mangaTitle,
    required String mangaId,
    required String chapterNum,
    required String chapterId,
    required String language,
    String? scanlationGroup,
    String? externalUrl,
    String? errorReason,
  }) async {
    final body = '''
### 🚨 Reporte de Capítulo Caído o No Disponible

* **Manga:** $mangaTitle
* **ID Manga:** `$mangaId`
* **Capítulo:** $chapterNum (ID: `$chapterId`)
* **Idioma:** $language
* **Scanlation / Grupo:** ${scanlationGroup ?? 'Desconocido'}
* **Enlace Externo (si aplica):** ${externalUrl ?? 'Ninguno'}
* **Problema:** ${errorReason ?? 'No hay páginas disponibles para visualización.'}
* **Versión de la App:** $currentVersion

---
*Reporte automático generado desde AppParaMiAmors Mobile*
''';

    final uri = Uri.parse(issuesUrl).replace(
      queryParameters: {
        'title': '[Capítulo Caído] $mangaTitle - Cap $chapterNum',
        'body': body,
      },
    );

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
