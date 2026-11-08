class Chapter {
  final String id;
  final String mangaId;
  final String chapter;
  final String? volume;
  final String? title;
  final String language;
  final DateTime? publishAt;
  final int pagesCount;
  final String? scanlationGroup;
  final String? externalUrl;

  const Chapter({
    required this.id,
    required this.mangaId,
    required this.chapter,
    this.volume,
    this.title,
    required this.language,
    this.publishAt,
    this.pagesCount = 0,
    this.scanlationGroup,
    this.externalUrl,
  });

  bool get isExternal => externalUrl != null && externalUrl!.trim().isNotEmpty;

  double get numericChapter => double.tryParse(chapter) ?? 0.0;

  String get displayName {
    final buffer = StringBuffer();
    if (chapter.isNotEmpty) {
      buffer.write('Capítulo $chapter');
    } else {
      buffer.write('One-shot / Especial');
    }
    if (title != null && title!.trim().isNotEmpty) {
      buffer.write(': ${title!.trim()}');
    }
    return buffer.toString();
  }

  String get languageDisplay {
    switch (language.toLowerCase()) {
      case 'es':
        return '🇪🇸 ES';
      case 'es-la':
        return '🇲🇽 ES-LA';
      case 'en':
        return '🇬🇧 EN';
      case 'pt-br':
        return '🇧🇷 PT';
      case 'fr':
        return '🇫🇷 FR';
      case 'it':
        return '🇮🇹 IT';
      case 'ja':
        return '🇯🇵 JA';
      default:
        return language.toUpperCase();
    }
  }

  factory Chapter.fromMangaDexJson(Map<String, dynamic> json, String mangaId) {
    final id = json['id'] as String? ?? '';
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    final chapterNum = attributes['chapter'] as String? ?? '';
    final volume = attributes['volume'] as String?;
    final title = attributes['title'] as String?;
    final language = attributes['translatedLanguage'] as String? ?? 'es';
    final pagesCount = attributes['pages'] as int? ?? 0;
    final externalUrl = attributes['externalUrl'] as String?;

    DateTime? publishAt;
    if (attributes['publishAt'] != null) {
      publishAt = DateTime.tryParse(attributes['publishAt'].toString());
    }

    // Grupo de scanlation
    String? groupName;
    final relationships = json['relationships'] as List<dynamic>? ?? [];
    for (final rel in relationships) {
      if (rel['type'] == 'scanlation_group') {
        final relAttr = rel['attributes'] as Map<String, dynamic>?;
        groupName = relAttr?['name'] as String?;
      }
    }

    return Chapter(
      id: id,
      mangaId: mangaId,
      chapter: chapterNum,
      volume: volume,
      title: title,
      language: language,
      publishAt: publishAt,
      pagesCount: pagesCount,
      scanlationGroup: groupName,
      externalUrl: externalUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mangaId': mangaId,
      'chapter': chapter,
      'volume': volume,
      'title': title,
      'language': language,
      'publishAt': publishAt?.toIso8601String(),
      'pagesCount': pagesCount,
      'scanlationGroup': scanlationGroup,
      'externalUrl': externalUrl,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] ?? '',
      mangaId: map['mangaId'] ?? '',
      chapter: map['chapter'] ?? '',
      volume: map['volume'],
      title: map['title'],
      language: map['language'] ?? 'es',
      publishAt: map['publishAt'] != null ? DateTime.tryParse(map['publishAt']) : null,
      pagesCount: map['pagesCount'] ?? 0,
      scanlationGroup: map['scanlationGroup'],
      externalUrl: map['externalUrl'],
    );
  }
}
