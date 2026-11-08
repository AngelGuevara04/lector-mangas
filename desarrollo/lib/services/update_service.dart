import 'dart:convert';
import 'package:http/http.dart' as http;
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
  static const String currentVersion = 'v1.0.2';
  static const String repoOwner = 'AngelGuevara04';
  static const String repoName = 'lector-mangas';

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
          'User-Agent': 'MangaFlow-App',
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
      // Si no hay internet o error de red, no se bloquea la app
    }

    return const UpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      changelog: '',
      releaseUrl: 'https://github.com/$repoOwner/$repoName/releases',
    );
  }

  /// Compara dos strings de versión semántica (e.g. v1.0.0 vs v1.0.1)
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
*Enviado desde MangaFlow Mobile*
''';

    final uri = Uri.parse(issuesUrl).replace(
      queryParameters: {
        'title': '[$category] $title',
        'body': body,
      },
    );

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
