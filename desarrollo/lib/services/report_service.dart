import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'update_service.dart';

class ReportService {
  static const String _supabaseUrl =
      'https://pqvlwcqfjqrukgvwfhnh.supabase.co/rest/v1/app_suggestions';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBxdmx3Y3FmanFydWtndndmaG5oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MjQ5MzYsImV4cCI6MjA5ODUwMDkzNn0.F1AYU6R5ri3DnZEdfsHA9dTRbZXEpNdjalZWd5nfWp8';

  /// Enviar una sugerencia o reporte de error directamente desde la aplicación sin abrir navegador
  static Future<bool> sendReport({
    required String type,
    required String title,
    required String description,
  }) async {
    final fullMessage = '[AppParaMiAmors] [$type] $title\n\n$description'.trim();
    final platform =
        Platform.isAndroid ? 'Android' : (Platform.isWindows ? 'Windows' : 'Otro');

    try {
      final res = await http.post(
        Uri.parse(_supabaseUrl),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode({
          'username': 'Usuario AppParaMiAmors',
          'type': type.toLowerCase(),
          'message': fullMessage,
          'app_version': UpdateService.currentVersion,
          'device_info': platform,
          'status': 'pending',
        }),
      );

      return res.statusCode == 201 || res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Reportar un capítulo caído directamente desde el lector sin abrir navegador
  static Future<bool> reportBrokenChapter({
    required String mangaTitle,
    required String mangaId,
    required String chapterNum,
    required String chapterId,
    required String language,
    String? scanlationGroup,
    String? externalUrl,
    String? errorReason,
  }) async {
    final message = '''[Capítulo Caído]
Manga: $mangaTitle (ID: $mangaId)
Capítulo: $chapterNum (ID: $chapterId)
Idioma: $language
Grupo: ${scanlationGroup ?? 'MangaDex'}
Enlace Externo: ${externalUrl ?? 'Ninguno'}
Error: ${errorReason ?? 'Sin páginas disponibles'}''';

    final platform =
        Platform.isAndroid ? 'Android' : (Platform.isWindows ? 'Windows' : 'Otro');

    try {
      final res = await http.post(
        Uri.parse(_supabaseUrl),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: json.encode({
          'username': 'Lector AppParaMiAmors',
          'type': 'capitulo_caido',
          'message': message,
          'app_version': UpdateService.currentVersion,
          'device_info': platform,
          'status': 'pending',
        }),
      );

      return res.statusCode == 201 || res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
