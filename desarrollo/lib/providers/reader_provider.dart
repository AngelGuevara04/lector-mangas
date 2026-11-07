import 'package:flutter/foundation.dart';
import '../services/mangadex_service.dart';
import '../services/storage_service.dart';
import '../models/chapter.dart';

enum ReadingMode {
  webtoonVertical, // Manhwa / Webtoon: Desplazamiento continuo vertical infinito
  mangaRTL,        // Manga japonés: De derecha a izquierda
  comicLTR,        // Cómic occidental: De izquierda a derecha
}

enum ReaderTheme {
  oledBlack, // Negro absoluto (#000000) - Máximo ahorro de batería
  darkGray,  // Gris oscuro (#141414)
  sepia,     // Sepia suave (#1a1714)
}

class ReaderProvider with ChangeNotifier {
  final MangaDexService _api = MangaDexService();
  final StorageService _storage = StorageService();

  Chapter? _currentChapter;
  Chapter? get currentChapter => _currentChapter;

  List<Chapter> _chapterList = [];
  int _currentChapterIndex = -1;

  List<String> _pageUrls = [];
  List<String> get pageUrls => _pageUrls;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  bool _showOverlay = true;
  bool get showOverlay => _showOverlay;

  bool _dataSaver = true;
  bool get dataSaver => _dataSaver;

  ReadingMode _mode = ReadingMode.webtoonVertical;
  ReadingMode get mode => _mode;

  ReaderTheme _theme = ReaderTheme.oledBlack;
  ReaderTheme get theme => _theme;

  bool get hasNextChapter =>
      _chapterList.isNotEmpty && _currentChapterIndex + 1 < _chapterList.length;

  bool get hasPreviousChapter =>
      _chapterList.isNotEmpty && _currentChapterIndex > 0;

  Chapter? get nextChapter =>
      hasNextChapter ? _chapterList[_currentChapterIndex + 1] : null;

  Chapter? get previousChapter =>
      hasPreviousChapter ? _chapterList[_currentChapterIndex - 1] : null;

  ReaderProvider() {
    _dataSaver = _storage.getDataSaver();
  }

  void toggleOverlay() {
    _showOverlay = !_showOverlay;
    notifyListeners();
  }

  void setOverlay(bool visible) {
    if (_showOverlay != visible) {
      _showOverlay = visible;
      notifyListeners();
    }
  }

  void setReadingMode(ReadingMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setTheme(ReaderTheme theme) {
    _theme = theme;
    notifyListeners();
  }

  void setPage(int page) {
    if (_currentPage != page && page >= 0 && page < _pageUrls.length) {
      _currentPage = page;
      notifyListeners();

      // Guardar progreso automáticamente
      if (_currentChapter != null) {
        _storage.saveProgress(
          mangaId: _currentChapter!.mangaId,
          chapterId: _currentChapter!.id,
          chapterNum: _currentChapter!.chapter,
          pageIndex: page,
          totalPages: _pageUrls.length,
        );
      }
    }
  }

  Future<void> toggleDataSaver() async {
    _dataSaver = !_dataSaver;
    await _storage.setDataSaver(_dataSaver);
    notifyListeners();
    if (_currentChapter != null) {
      await loadChapter(_currentChapter!, keepPage: true);
    }
  }

  void setChapterContext({
    required List<Chapter> chapters,
    required Chapter activeChapter,
  }) {
    _chapterList = chapters;
    _currentChapterIndex = chapters.indexWhere((c) => c.id == activeChapter.id);
  }

  Future<void> goToNextChapter() async {
    if (hasNextChapter) {
      _currentChapterIndex++;
      await loadChapter(_chapterList[_currentChapterIndex]);
    }
  }

  Future<void> goToPreviousChapter() async {
    if (hasPreviousChapter) {
      _currentChapterIndex--;
      await loadChapter(_chapterList[_currentChapterIndex]);
    }
  }

  Future<void> loadChapter(Chapter chapter, {bool keepPage = false}) async {
    _currentChapter = chapter;
    _isLoading = true;
    _error = null;
    if (!keepPage) _currentPage = 0;
    _pageUrls = [];
    notifyListeners();

    try {
      _pageUrls = await _api.getChapterPages(chapter.id, dataSaver: _dataSaver);
      if (_pageUrls.isEmpty) {
        _error = 'Este capítulo no tiene páginas disponibles para visualización.';
      }
    } catch (e) {
      _error = 'Error al cargar las páginas del capítulo. Verifica tu conexión.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
