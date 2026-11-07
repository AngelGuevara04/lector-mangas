import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manga.dart';

class StorageService {
  static const _keyFavorites = 'amors_favorites';
  static const _keyHistory = 'amors_history';
  static const _keySettingsDataSaver = 'settings_data_saver';
  static const _keySettingsLanguage = 'settings_language';
  static const _keySettingsReadingMode = 'settings_reading_mode';

  // Singleton
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

  // --- Historial de lectura ---
  Map<String, dynamic> getReadingHistory() {
    final raw = _prefs?.getString(_keyHistory);
    if (raw == null) return {};
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> saveProgress({
    required String mangaId,
    required String chapterId,
    required String chapterNum,
    required int pageIndex,
    required int totalPages,
  }) async {
    final history = getReadingHistory();
    history[mangaId] = {
      'chapterId': chapterId,
      'chapterNum': chapterNum,
      'pageIndex': pageIndex,
      'totalPages': totalPages,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs?.setString(_keyHistory, json.encode(history));
  }

  Map<String, dynamic>? getMangaProgress(String mangaId) {
    final history = getReadingHistory();
    return history[mangaId] as Map<String, dynamic>?;
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
