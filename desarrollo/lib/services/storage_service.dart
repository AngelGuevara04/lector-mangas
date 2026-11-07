import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/manga.dart';

class HistoryEntry {
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final String chapterId;
  final String chapterNum;
  final int pageIndex;
  final int totalPages;
  final int timestamp;

  const HistoryEntry({
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    required this.chapterId,
    required this.chapterNum,
    required this.pageIndex,
    required this.totalPages,
    required this.timestamp,
  });

  int get progressPercent =>
      totalPages > 0 ? (((pageIndex + 1) / totalPages) * 100).round() : 0;

  Map<String, dynamic> toMap() => {
        'mangaId': mangaId,
        'mangaTitle': mangaTitle,
        'coverUrl': coverUrl,
        'chapterId': chapterId,
        'chapterNum': chapterNum,
        'pageIndex': pageIndex,
        'totalPages': totalPages,
        'timestamp': timestamp,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        mangaId: map['mangaId'] ?? '',
        mangaTitle: map['mangaTitle'] ?? '',
        coverUrl: map['coverUrl'],
        chapterId: map['chapterId'] ?? '',
        chapterNum: map['chapterNum'] ?? '',
        pageIndex: map['pageIndex'] ?? 0,
        totalPages: map['totalPages'] ?? 0,
        timestamp: map['timestamp'] ?? 0,
      );
}

class StorageService {
  static const _keyFavorites = 'amors_favorites';
  static const _keyHistory = 'amors_history_v2';
  static const _keySettingsDataSaver = 'settings_data_saver';
  static const _keySettingsLanguage = 'settings_language';
  static const _keySettingsReadingMode = 'settings_reading_mode';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // --- Favoritos / Biblioteca ---
  List<Manga> getFavorites() {
    final raw = _prefs?.getStringList(_keyFavorites) ?? [];
    return raw
        .map((str) => Manga.fromMap(json.decode(str) as Map<String, dynamic>))
        .toList();
  }

  bool isFavorite(String mangaId) {
    final list = getFavorites();
    return list.any((m) => m.id == mangaId);
  }

  Future<void> toggleFavorite(Manga manga) async {
    final list = getFavorites();
    final index = list.indexWhere((m) => m.id == manga.id);
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.insert(0, manga);
    }
    final encoded = list.map((m) => json.encode(m.toMap())).toList();
    await _prefs?.setStringList(_keyFavorites, encoded);
  }

  // --- Historial de lectura enriquecido ---
  List<HistoryEntry> getReadingHistory() {
    final raw = _prefs?.getStringList(_keyHistory) ?? [];
    final entries = raw
        .map((str) => HistoryEntry.fromMap(json.decode(str) as Map<String, dynamic>))
        .toList();
    // Ordenar del más reciente al más antiguo
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> saveProgress({
    required String mangaId,
    String? mangaTitle,
    String? coverUrl,
    required String chapterId,
    required String chapterNum,
    required int pageIndex,
    required int totalPages,
  }) async {
    final history = getReadingHistory();
    final index = history.indexWhere((h) => h.mangaId == mangaId);

    final title = (mangaTitle != null && mangaTitle.isNotEmpty)
        ? mangaTitle
        : (index >= 0 ? history[index].mangaTitle : 'Manga');

    final cover = coverUrl ?? (index >= 0 ? history[index].coverUrl : null);

    final newEntry = HistoryEntry(
      mangaId: mangaId,
      mangaTitle: title,
      coverUrl: cover,
      chapterId: chapterId,
      chapterNum: chapterNum,
      pageIndex: pageIndex,
      totalPages: totalPages,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    if (index >= 0) {
      history.removeAt(index);
    }
    history.insert(0, newEntry);

    // Mantener máximo 50 entradas en historial para no saturar memoria
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final encoded = history.map((e) => json.encode(e.toMap())).toList();
    await _prefs?.setStringList(_keyHistory, encoded);
  }

  HistoryEntry? getMangaProgress(String mangaId) {
    final list = getReadingHistory();
    final index = list.indexWhere((h) => h.mangaId == mangaId);
    return index >= 0 ? list[index] : null;
  }

  Future<void> clearHistory() async {
    await _prefs?.remove(_keyHistory);
  }

  // --- Gestión de Almacenamiento y Caché ---
  Future<void> clearImageCache() async {
    await DefaultCacheManager().emptyCache();
  }

  // --- Ajustes ---
  bool getDataSaver() => _prefs?.getBool(_keySettingsDataSaver) ?? true;
  Future<void> setDataSaver(bool val) async =>
      await _prefs?.setBool(_keySettingsDataSaver, val);

  String getLanguagePreference() =>
      _prefs?.getString(_keySettingsLanguage) ?? 'es';
  Future<void> setLanguagePreference(String lang) async =>
      await _prefs?.setString(_keySettingsLanguage, lang);

  String getReadingModePreference() =>
      _prefs?.getString(_keySettingsReadingMode) ?? 'vertical';
  Future<void> setReadingModePreference(String mode) async =>
      await _prefs?.setString(_keySettingsReadingMode, mode);
}
