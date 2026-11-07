import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manga.dart';
import '../models/chapter.dart';
import '../providers/manga_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapters();
    });
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

    final displayedChapters = _isAscending
        ? chapters
        : chapters.reversed.toList();

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

                      // Botón Leer primer capítulo
                      if (chapters.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book),
                            label: Text('Empezar a Leer (${chapters.first.displayName})'),
                            onPressed: () {
                              _openReader(context, chapters.first);
                            },
                          ),
                        ),

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

                      // Barra de control de capítulos (Idioma y orden)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Capítulos (${chapters.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
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
                              const SizedBox(width: 8),
                              // Invertir orden
                              IconButton(
                                icon: Icon(
                                  _isAscending ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 20,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() => _isAscending = !_isAscending);
                                },
                              ),
                            ],
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
                      'No se encontraron capítulos en este idioma.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
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
                (context, index) {
                  final ch = displayedChapters[index];
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(
                        ch.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${ch.languageDisplay} • ${ch.scanlationGroup ?? 'MangaDex'} • ${ch.pagesCount} págs',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                      onTap: () => _openReader(context, ch),
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

  void _openReader(BuildContext context, Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapter: chapter,
          isWebtoon: widget.manga.prefersWebtoonLayout,
        ),
      ),
    );
  }
}
