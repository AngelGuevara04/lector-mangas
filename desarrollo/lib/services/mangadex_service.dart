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

  /// Búsqueda avanzada de manga con soporte de filtros (idioma original, texto, estado, orden, y zona H/+18)
  Future<List<Manga>> searchManga({
    String? query,
    String? originalLanguage,
    String? status,
    String? genreTagId,
    String sortOrder = 'relevance',
    bool isHentai = false,
    int limit = 24,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit.toString(),
      'offset': offset.toString(),
      'includes[]': 'cover_art',
    };

    // Clasificación de contenido: Zona H vs Contenido Estándar
    if (isHentai) {
      queryParams['contentRating[]'] = ['erotica', 'pornographic'];
    } else {
      queryParams['contentRating[]'] = ['safe', 'suggestive'];
    }

    if (query != null && query.trim().isNotEmpty) {
      queryParams['title'] = query.trim();
    }

    if (genreTagId != null && genreTagId.isNotEmpty) {
      queryParams['includedTags[]'] = [genreTagId];
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

  /// Obtiene los capítulos de un manga con paginación extendida y deduplicación inteligente
  Future<List<Chapter>> getChapters(
    String mangaId, {
    List<String> languages = const ['es', 'es-la'],
    String order = 'asc',
  }) async {
    final allChapters = <Chapter>[];
    int offset = 0;
    const int pageSize = 100;
    int total = 0;

    try {
      // Paginamos hasta obtener todos los capítulos (máximo 500 para evitar bloqueos)
      do {
        final queryParams = <String, dynamic>{
          'limit': pageSize.toString(),
          'offset': offset.toString(),
          'includes[]': 'scanlation_group',
          'order[chapter]': order,
          'contentRating[]': ['safe', 'suggestive', 'erotica', 'pornographic'],
        };

        if (languages.isNotEmpty) {
          queryParams['translatedLanguage[]'] = languages;
        }

        final uri = Uri.parse('$baseUrl/manga/$mangaId/feed').replace(
          queryParameters: _encodeQueryParameters(queryParams),
        );

        final response = await http.get(uri, headers: defaultHeaders);
        if (response.statusCode != 200) break;

        final data = json.decode(response.body);
        total = data['total'] as int? ?? 0;
        final list = data['data'] as List<dynamic>? ?? [];
        if (list.isEmpty) break;

        for (final item in list) {
          allChapters.add(Chapter.fromMangaDexJson(item, mangaId));
        }

        offset += pageSize;
      } while (offset < total && offset < 500);

      // Si no hay capítulos en español, intentamos en inglés para que no quede vacío
      if (allChapters.isEmpty && languages.any((l) => l.startsWith('es'))) {
        return getChapters(mangaId, languages: ['en'], order: order);
      }

      // Deduplicación inteligente: si un capítulo está repetido por varios scanlations,
      // priorizamos el que tenga páginas reales (pagesCount > 0) y sin externalUrl
      final chapterMap = <String, Chapter>{};
      for (final ch in allChapters) {
        final key = '${ch.chapter}_${ch.language}';
        if (!chapterMap.containsKey(key)) {
          chapterMap[key] = ch;
        } else {
          final existing = chapterMap[key]!;
          // Si el existente es externo (ej. MangaPlus sin páginas) pero el nuevo tiene páginas, lo reemplazamos
          if (existing.isExternal && !ch.isExternal && ch.pagesCount > 0) {
            chapterMap[key] = ch;
          } else if (ch.pagesCount > existing.pagesCount) {
            chapterMap[key] = ch;
          }
        }
      }

      final deduplicated = chapterMap.values.toList();

      // Ordenar numéricamente (1, 2, 3... 10... 100) en lugar de alfabético ("1", "10", "2")
      deduplicated.sort((a, b) {
        final comp = a.numericChapter.compareTo(b.numericChapter);
        return order == 'asc' ? comp : -comp;
      });

      return deduplicated;
    } catch (_) {}
    return allChapters;
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
