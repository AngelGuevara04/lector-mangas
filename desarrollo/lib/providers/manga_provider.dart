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

  String? _selectedGenreId;
  String? get selectedGenreId => _selectedGenreId;

  static const Map<String, String> popularGenres = {
    'Todos los géneros': '',
    'Acción': '391b0423-d847-456f-aff0-8b0cfc03066b',
    'Romance': '423e2eae-a7a2-4a8b-ac03-a8351462d71d',
    'Comedia': '4d32cc48-9f00-4cca-9b5a-a839f0764984',
    'Fantasía': 'cdc58593-87dd-415e-bbc0-2ec27bf404cc',
    'Isekai': 'ace04997-f6bd-436e-b261-779182193d3d',
    'Drama': 'b9af3a63-f058-46de-a9a0-e0c13906197a',
    'Terror': 'cdad7e68-1419-41dd-bdce-27753074a640',
    'Misterio': 'ee968100-4191-4968-93d3-f82d72be7e46',
    'Sobrenatural': 'eabc5b4c-6aff-42f3-b657-3e90cbd00b75',
    'Ciencia Ficción': '256c8bd9-4904-4360-bf4f-508a76d67183',
    'Deportes': '69964a64-2f90-4d33-beeb-f3ed2875eb4c',
  };

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
        genreTagId: _selectedGenreId,
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

  void setGenre(String? genreId) {
    final clean = (genreId != null && genreId.isNotEmpty) ? genreId : null;
    if (_selectedGenreId == clean) return;
    _selectedGenreId = clean;
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
          genreTagId: _selectedGenreId,
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
