import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga.dart';
import '../models/chapter.dart';

class MangaDexService {
  static const String baseUrl = 'https://api.mangadex.org';
  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'MangaFlow/1.0.2 (https://github.com/AngelGuevara04/lector-mangas)',
    'Accept': 'application/json',
  };

  /// Búsqueda avanzada de manga con soporte de filtros (idioma original, texto, estado, orden)
  Future<List<Manga>> searchManga({
    String? query,
    String? originalLanguage,
    String? status,
    String sortOrder = 'relevance',
    int limit = 24,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'includes[]': 'cover_art',
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParams['title'] = query.trim();
    }

    if (originalLanguage != null && originalLanguage != 'all') {
      queryParams['originalLanguage[]'] = originalLanguage;
    }

    if (status != null && status != 'all') {
      queryParams['status[]'] = status;
    }

    // Orden de resultados
    switch (sortOrder) {
      case 'popular':
        queryParams['order[followedCount]'] = 'desc';
        break;
      case 'rating':
        queryParams['order[rating]'] = 'desc';
        break;
      case 'latest':
        queryParams['order[latestUploadedChapter]'] = 'desc';
        break;
      default:
        queryParams['order[relevance]'] = 'desc';
    }

    final uri = Uri.parse('$baseUrl/manga').replace(
      queryParameters: _encodeQueryParameters(queryParams),
    );

    try {
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map((item) => Manga.fromMangaDexJson(item)).toList();
      } else {
        throw Exception('Error al buscar títulos: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene los mangas más populares
  Future<List<Manga>> getPopularManga({
    int limit = 24,
    int offset = 0,
    String? originalLanguage,
    String sortOrder = 'popular',
  }) async {
    return searchManga(
      originalLanguage: originalLanguage,
      sortOrder: sortOrder,
      limit: limit,
      offset: offset,
    );
  }

  /// Obtiene los capítulos de un manga
  Future<List<Chapter>> getChapters(
    String mangaId, {
    List<String> languages = const ['es', 'es-la'],
    String order = 'asc',
  }) async {
    final queryParams = <String, dynamic>{
      'limit': '100',
      'includes[]': 'scanlation_group',
      'order[chapter]': order,
      'contentRating[]': ['safe', 'suggestive'],
    };

    if (languages.isNotEmpty) {
      queryParams['translatedLanguage[]'] = languages;
    }

    final uri = Uri.parse('$baseUrl/manga/$mangaId/feed').replace(
      queryParameters: _encodeQueryParameters(queryParams),
    );

    try {
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['data'] as List<dynamic>? ?? [];
        return list.map((item) => Chapter.fromMangaDexJson(item, mangaId)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Obtiene un manga específico por su ID
  Future<Manga?> getMangaById(String mangaId) async {
    final uri = Uri.parse('$baseUrl/manga/$mangaId?includes[]=cover_art');
    try {
      final response = await http.get(uri, headers: defaultHeaders);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Manga.fromMangaDexJson(data['data']);
      }
    } catch (_) {}
    return null;
  }

  /// Obtiene las URLs de las páginas de un capítulo
  /// [dataSaver] usa imágenes WebP comprimidas ideales para teléfonos de gama baja o conexiones lentas
  Future<List<String>> getChapterPages(
    String chapterId, {
    bool dataSaver = true,
  }) async {
    final uri = Uri.parse('$baseUrl/at-home/server/$chapterId');
    final response = await http.get(uri, headers: defaultHeaders);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final baseUrlNode = data['baseUrl'] as String;
      final chapterData = data['chapter'] as Map<String, dynamic>;
      final hash = chapterData['hash'] as String;

      final fileList = dataSaver
          ? (chapterData['dataSaver'] as List<dynamic>? ?? [])
          : (chapterData['data'] as List<dynamic>? ?? []);

      final modePath = dataSaver ? 'data-saver' : 'data';

      return fileList
          .map((fileName) => '$baseUrlNode/$modePath/$hash/$fileName')
          .toList();
    } else {
      throw Exception('No se pudieron obtener las páginas del capítulo.');
    }
  }

  static Map<String, dynamic> _encodeQueryParameters(Map<String, dynamic> params) {
    final result = <String, dynamic>{};
    params.forEach((key, value) {
      if (value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }
}
