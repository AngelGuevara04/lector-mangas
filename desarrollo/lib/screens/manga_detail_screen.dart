import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../providers/manga_provider.dart';
import '../services/storage_service.dart';
import '../widgets/optimized_image.dart';
import 'reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final Manga manga;

  const MangaDetailScreen({super.key, required this.manga});

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  bool _isAscending = true;
  String _selectedLang = 'es';
  bool _expandDesc = false;
  bool _showChapterSearch = false;
  String _chapterSearch = '';
  final TextEditingController _chapterSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapters();
    });
  }

  @override
  void dispose() {
    _chapterSearchCtrl.dispose();
    super.dispose();
  }

  void _loadChapters() {
    final provider = Provider.of<MangaProvider>(context, listen: false);
    final langs = _selectedLang == 'es' ? ['es', 'es-la'] : [_selectedLang];
    provider.loadChapters(widget.manga.id, languages: langs);
  }

  @override
  Widget build(BuildContext context) {
    final mangaProvider = Provider.of<MangaProvider>(context);
    final isFav = mangaProvider.isFavorite(widget.manga.id);
    final chapters = mangaProvider.currentChapters;
    final lastProgress = StorageService().getMangaProgress(widget.manga.id);

    List<Chapter> displayedChapters = _isAscending
        ? List.from(chapters)
        : chapters.reversed.toList();

    if (_chapterSearch.trim().isNotEmpty) {
      final q = _chapterSearch.trim().toLowerCase();
      displayedChapters = displayedChapters.where((ch) {
        final dName = ch.displayName.toLowerCase();
        final cNum = ch.chapter.toLowerCase();
        final cTitle = (ch.title ?? '').toLowerCase();
        return dName.contains(q) || cNum.contains(q) || cTitle.contains(q);
      }).toList();
    }

    // Identificar capítulo a continuar
    Chapter? resumeChapter;
    if (lastProgress != null && chapters.isNotEmpty) {
      final matches = chapters.where((c) => c.id == lastProgress.chapterId);
      if (matches.isNotEmpty) {
        resumeChapter = matches.first;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : Colors.white,
            ),
            onPressed: () {
              mangaProvider.toggleFavorite(widget.manga);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          // Cabecera con portada y detalles
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Fondo con degradado
                if (widget.manga.coverUrl != null)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.15,
                      child: OptimizedImage(
                        imageUrl: widget.manga.coverUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 90, 16, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0xFF121212),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Portada
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 110,
                              height: 160,
                              child: widget.manga.coverUrl != null
                                  ? OptimizedImage(imageUrl: widget.manga.coverUrl!)
                                  : Container(color: Colors.grey[850]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Metadatos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.manga.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.deepPurpleAccent, width: 0.5),
                                  ),
                                  child: Text(
                                    widget.manga.comicType,
                                    style: const TextStyle(
                                      color: Colors.purpleAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Estado: ${widget.manga.status.toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                if (widget.manga.year != null)
                                  Text(
                                    'Año: ${widget.manga.year}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Botón de lectura (Continuar o Empezar)
                      if (chapters.isNotEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(
                              resumeChapter != null ? Icons.play_arrow_rounded : Icons.menu_book,
                              size: 22,
                            ),
                            label: Text(
                              resumeChapter != null
                                  ? 'Continuar: ${resumeChapter.displayName} (Pág. ${lastProgress!.pageIndex + 1}/${lastProgress.totalPages})'
                                  : 'Empezar a Leer (${chapters.first.displayName})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final targetChapter = resumeChapter ?? chapters.first;
                              final page = (resumeChapter != null && lastProgress != null)
                                  ? lastProgress.pageIndex
                                  : 0;
                              _openReader(context, targetChapter, initialPage: page);
                            },
                          ),
                        ),
                        if (resumeChapter != null && resumeChapter != chapters.first)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: Colors.white60,
                                ),
                                icon: const Icon(Icons.first_page, size: 18),
                                label: Text(
                                  'Empezar desde el inicio (${chapters.first.displayName})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  _openReader(context, chapters.first, initialPage: 0);
                                },
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 14),

                      // Sinopsis
                      GestureDetector(
                        onTap: () => setState(() => _expandDesc = !_expandDesc),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sinopsis',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.manga.description,
                              maxLines: _expandDesc ? 50 : 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            if (widget.manga.description.length > 120)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _expandDesc ? 'Mostrar menos' : 'Leer más...',
                                  style: const TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 28),

                      // Barra de control de capítulos (Idioma, búsqueda y orden)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _chapterSearch.isNotEmpty
                                    ? 'Capítulos (${displayedChapters.length}/${chapters.length})'
                                    : 'Capítulos (${chapters.length})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Row(
                                children: [
                                  // Botón buscar capítulo
                                  IconButton(
                                    icon: Icon(
                                      _showChapterSearch ? Icons.search_off : Icons.search,
                                      size: 20,
                                      color: _showChapterSearch ? Colors.deepPurpleAccent : Colors.white70,
                                    ),
                                    tooltip: 'Buscar capítulo',
                                    onPressed: () {
                                      setState(() {
                                        _showChapterSearch = !_showChapterSearch;
                                        if (!_showChapterSearch) {
                                          _chapterSearchCtrl.clear();
                                          _chapterSearch = '';
                                        }
                                      });
                                    },
                                  ),
                                  // Selector de idioma
                                  DropdownButton<String>(
                                    value: _selectedLang,
                                    dropdownColor: const Color(0xFF222222),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'es', child: Text('🇲🇽 Español')),
                                      DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null && val != _selectedLang) {
                                        setState(() => _selectedLang = val);
                                        _loadChapters();
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  // Invertir orden
                                  IconButton(
                                    icon: Icon(
                                      _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    tooltip: _isAscending ? 'Orden: 1 a N' : 'Orden: N a 1',
                                    onPressed: () {
                                      setState(() => _isAscending = !_isAscending);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_showChapterSearch)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: TextField(
                                controller: _chapterSearchCtrl,
                                autofocus: true,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Filtrar por número o nombre (ej: 105, Especial)...',
                                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                                  prefixIcon: const Icon(Icons.search, color: Colors.deepPurpleAccent, size: 18),
                                  suffixIcon: _chapterSearch.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                                          onPressed: () {
                                            setState(() {
                                              _chapterSearchCtrl.clear();
                                              _chapterSearch = '';
                                            });
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) {
                                  setState(() => _chapterSearch = val);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de capítulos
          if (mangaProvider.isLoadingChapters)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                ),
              ),
            )
          else if (displayedChapters.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, color: Colors.white24, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _chapterSearch.isNotEmpty
                          ? 'No se encontraron capítulos con "$_chapterSearch".'
                          : 'No se encontraron capítulos en este idioma.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (_chapterSearch.isEmpty)
                      TextButton(
                        child: const Text('Buscar en Inglés'),
                        onPressed: () {
                          setState(() => _selectedLang = 'en');
                          _loadChapters();
                        },
                      ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, index) {
                  final ch = displayedChapters[index];
                  final isRead = StorageService().isChapterRead(ch.id);
                  final isCurrent = resumeChapter?.id == ch.id;

                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Row(
                        children: [
                          if (isRead)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check_circle, size: 15, color: Colors.tealAccent),
                            ),
                          Expanded(
                            child: Text(
                              ch.displayName,
                              style: TextStyle(
                                color: isRead ? Colors.white60 : Colors.white,
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.deepPurpleAccent, width: 0.5),
                              ),
                              child: const Text(
                                'Leyendo',
                                style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (ch.isExternal)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blueAccent, width: 0.5),
                              ),
                              child: const Text(
                                'MangaPlus',
                                style: TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        ch.isExternal
                            ? '${ch.languageDisplay} • Publicación Oficial Directa'
                            : '${ch.languageDisplay} • ${ch.scanlationGroup ?? 'MangaDex'} • ${ch.pagesCount} págs',
                        style: TextStyle(color: isRead ? Colors.grey[600] : Colors.grey[500], fontSize: 12),
                      ),
                      trailing: Icon(
                        ch.isExternal ? Icons.open_in_new : Icons.arrow_forward_ios,
                        size: 14,
                        color: ch.isExternal ? Colors.lightBlueAccent : Colors.white38,
                      ),
                      onTap: () {
                        final isResume = resumeChapter?.id == ch.id;
                        final page = (isResume && lastProgress != null) ? lastProgress.pageIndex : 0;
                        _openReader(context, ch, initialPage: page);
                      },
                      onLongPress: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await StorageService().toggleChapterRead(ch.id);
                        if (!mounted) return;
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isRead
                                  ? '${ch.displayName}: marcado como no leído'
                                  : '${ch.displayName}: marcado como leído ✓',
                            ),
                            duration: const Duration(milliseconds: 1400),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: displayedChapters.length,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openReader(BuildContext context, Chapter chapter, {int initialPage = 0}) async {
    final mangaProvider = Provider.of<MangaProvider>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapter: chapter,
          manga: widget.manga,
          allChapters: _isAscending
              ? mangaProvider.currentChapters
              : mangaProvider.currentChapters.reversed.toList(),
          isWebtoon: widget.manga.prefersWebtoonLayout,
          initialPage: initialPage,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}
