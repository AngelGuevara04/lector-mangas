import 'package:flutter/foundation.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../services/mangadex_service.dart';
import '../services/storage_service.dart';

class MangaProvider with ChangeNotifier {
  final MangaDexService _api = MangaDexService();
  final StorageService _storage = StorageService();

  List<Manga> _items = [];
  List<Manga> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedCategory = 'all'; // 'all', 'ko' (Manhwa), 'ja' (Manga), 'zh' (Manhua)
  String get selectedCategory => _selectedCategory;

  String _sortOrder = 'popular'; // 'popular', 'rating', 'latest'
  String get sortOrder => _sortOrder;

  String _statusFilter = 'all'; // 'all', 'ongoing', 'completed'
  String get statusFilter => _statusFilter;

  bool _isHentaiZone = false;
  bool get isHentaiZone => _isHentaiZone;

  List<Manga> _favorites = [];
  List<Manga> get favorites => _favorites;

  List<HistoryEntry> _history = [];
  List<HistoryEntry> get history => _history;

  // Detalles del manga actual
  List<Chapter> _currentChapters = [];
  List<Chapter> get currentChapters => _currentChapters;
  bool _isLoadingChapters = false;
  bool get isLoadingChapters => _isLoadingChapters;

  MangaProvider() {
    loadFavorites();
    loadHistory();
    fetchInitial();
  }

  void loadFavorites() {
    _favorites = _storage.getFavorites();
    notifyListeners();
  }

  void loadHistory() {
    _history = _storage.getReadingHistory();
    notifyListeners();
  }

  bool isFavorite(String id) => _storage.isFavorite(id);

  Future<void> toggleFavorite(Manga manga) async {
    await _storage.toggleFavorite(manga);
    loadFavorites();
  }

  Future<void> fetchInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _api.searchManga(
        originalLanguage: _selectedCategory == 'all' ? null : _selectedCategory,
        status: _statusFilter == 'all' ? null : _statusFilter,
        sortOrder: _sortOrder,
        isHentai: _isHentaiZone,
      );
    } catch (e) {
      _error = 'No se pudo conectar con el servidor. Revisa tu conexión.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _executeSearchOrFetch();
  }

  void setSortOrder(String sort) {
    if (_sortOrder == sort) return;
    _sortOrder = sort;
    _executeSearchOrFetch();
  }

  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    _executeSearchOrFetch();
  }

  void setHentaiZone(bool isHentai) {
    if (_isHentaiZone == isHentai) return;
    _isHentaiZone = isHentai;
    _executeSearchOrFetch();
  }

  void _executeSearchOrFetch() {
    if (_searchQuery.trim().isEmpty) {
      fetchInitial();
    } else {
      search(_searchQuery);
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.trim().isEmpty) {
        await fetchInitial();
      } else {
        _items = await _api.searchManga(
          query: query,
          originalLanguage: _selectedCategory == 'all' ? null : _selectedCategory,
          status: _statusFilter == 'all' ? null : _statusFilter,
          sortOrder: _sortOrder,
          isHentai: _isHentaiZone,
        );
      }
    } catch (e) {
      _error = 'Error en la búsqueda. Intenta con otro término.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChapters(String mangaId, {List<String>? languages}) async {
    _isLoadingChapters = true;
    _currentChapters = [];
    notifyListeners();

    try {
      final langPref = _storage.getLanguagePreference();
      final targetLangs = languages ?? (langPref == 'es' ? ['es', 'es-la'] : [langPref]);

      _currentChapters = await _api.getChapters(
        mangaId,
        languages: targetLangs,
        order: 'asc',
      );

      // Si no hay en español, intentar buscar en inglés para que el usuario no se quede sin leer
      if (_currentChapters.isEmpty && langPref == 'es') {
        _currentChapters = await _api.getChapters(
          mangaId,
          languages: ['en'],
          order: 'asc',
        );
      }
    } catch (e) {
      _currentChapters = [];
    } finally {
      _isLoadingChapters = false;
      notifyListeners();
    }
  }

  Future<Manga?> getManga(String mangaId) async {
    return await _api.getMangaById(mangaId);
  }
}
