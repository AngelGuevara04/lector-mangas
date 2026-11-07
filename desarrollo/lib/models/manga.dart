class Manga {
  final String id;
  final String title;
  final String? coverUrl;
  final String description;
  final String status;
  final String originalLanguage;
  final List<String> tags;
  final int? year;
  final List<String> availableLanguages;

  const Manga({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.description,
    required this.status,
    required this.originalLanguage,
    this.tags = const [],
    this.year,
    this.availableLanguages = const [],
  });

  /// Clasifica según el país de origen
  String get comicType {
    switch (originalLanguage.toLowerCase()) {
      case 'ko':
        return 'Manhwa (Corea)';
      case 'zh':
      case 'zh-hk':
        return 'Manhua (China)';
      case 'ja':
        return 'Manga (Japón)';
      default:
        return 'Cómic / Otro';
    }
  }

  /// Retorna si típicamente se lee en formato vertical (Webtoon)
  bool get prefersWebtoonLayout {
    return originalLanguage.toLowerCase() == 'ko' ||
        tags.any((t) => t.toLowerCase().contains('webtoon'));
  }

  factory Manga.fromMangaDexJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    // Título (busca en español, luego inglés, o el primer disponible)
    final titleMap = attributes['title'] as Map<String, dynamic>? ?? {};
    String title = titleMap['es-la'] ??
        titleMap['es'] ??
        titleMap['en'] ??
        (titleMap.isNotEmpty ? titleMap.values.first.toString() : 'Sin título');

    // Descripción
    final descMap = attributes['description'] as Map<String, dynamic>? ?? {};
    String description = descMap['es-la'] ??
        descMap['es'] ??
        descMap['en'] ??
        (descMap.isNotEmpty ? descMap.values.first.toString() : 'Sin descripción disponible.');

    // Estado
    final status = attributes['status'] as String? ?? 'Desconocido';
    final originalLanguage = attributes['originalLanguage'] as String? ?? 'ja';
    final year = attributes['year'] as int?;

    // Tags
    final tagsList = <String>[];
    if (attributes['tags'] is List) {
      for (final t in attributes['tags']) {
        final tAttr = t['attributes'] as Map<String, dynamic>?;
        if (tAttr != null && tAttr['name'] is Map) {
          final nameMap = tAttr['name'] as Map<String, dynamic>;
          final tagName = nameMap['es'] ?? nameMap['en'];
          if (tagName != null) tagsList.add(tagName.toString());
        }
      }
    }

    // Portada
    String? coverUrl;
    final relationships = json['relationships'] as List<dynamic>? ?? [];
    for (final rel in relationships) {
      if (rel['type'] == 'cover_art') {
        final relAttr = rel['attributes'] as Map<String, dynamic>?;
        final fileName = relAttr?['fileName'] as String?;
        if (fileName != null && fileName.isNotEmpty) {
          // Usamos la miniatura optimizada de 256px para no saturar la memoria RAM
          coverUrl = 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg';
        }
      }
    }

    // Idiomas disponibles
    final availableLanguages = <String>[];
    if (attributes['availableTranslatedLanguages'] is List) {
      for (final lang in attributes['availableTranslatedLanguages']) {
        if (lang != null) availableLanguages.add(lang.toString());
      }
    }

    return Manga(
      id: id,
      title: title,
      coverUrl: coverUrl,
      description: description,
      status: status,
      originalLanguage: originalLanguage,
      tags: tagsList,
      year: year,
      availableLanguages: availableLanguages,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'description': description,
      'status': status,
      'originalLanguage': originalLanguage,
      'tags': tags,
      'year': year,
      'availableLanguages': availableLanguages,
    };
  }

  factory Manga.fromMap(Map<String, dynamic> map) {
    return Manga(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      coverUrl: map['coverUrl'],
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      originalLanguage: map['originalLanguage'] ?? 'ja',
      tags: List<String>.from(map['tags'] ?? []),
      year: map['year'],
      availableLanguages: List<String>.from(map['availableLanguages'] ?? []),
    );
  }
}
