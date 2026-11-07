import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../providers/reader_provider.dart';
import '../widgets/optimized_image.dart';

class ReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final List<Chapter> allChapters;
  final bool isWebtoon;

  const ReaderScreen({
    super.key,
    required this.chapter,
    this.allChapters = const [],
    this.isWebtoon = false,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reader = Provider.of<ReaderProvider>(context, listen: false);
      if (widget.isWebtoon) {
        reader.setReadingMode(ReadingMode.webtoonVertical);
      }
      if (widget.allChapters.isNotEmpty) {
        reader.setChapterContext(
          chapters: widget.allChapters,
          activeChapter: widget.chapter,
        );
      }
      reader.loadChapter(widget.chapter);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.oledBlack:
        return Colors.black;
      case ReaderTheme.darkGray:
        return const Color(0xFF141414);
      case ReaderTheme.sepia:
        return const Color(0xFF181512);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reader = Provider.of<ReaderProvider>(context);
    final bgColor = _getBackgroundColor(reader.theme);
    final currentCh = reader.currentChapter ?? widget.chapter;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Área principal de lectura
          if (reader.isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Cargando páginas...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (reader.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      reader.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
                      onPressed: () => reader.loadChapter(currentCh),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildReaderContent(reader),

          // Línea delgada de progreso de lectura inferior (visible incluso sin menú)
          if (!reader.showOverlay && reader.pageUrls.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: (reader.currentPage + 1) / reader.pageUrls.length,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                minHeight: 2.5,
              ),
            ),

          // Barra Superior (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: reader.showOverlay ? 0 : -100,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 4,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              color: Colors.black.withValues(alpha: 0.88),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentCh.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reader.pageUrls.isNotEmpty)
                          Text(
                            'Página ${reader.currentPage + 1} de ${reader.pageUrls.length}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  // Botón Ahorro de Datos (WebP / Memoria Ligera)
                  IconButton(
                    icon: Icon(
                      reader.dataSaver ? Icons.bolt : Icons.hd_outlined,
                      color: reader.dataSaver ? Colors.amberAccent : Colors.white70,
                    ),
                    tooltip: reader.dataSaver ? 'Modo Ultra Ligero (Activo)' : 'Modo Alta Definición',
                    onPressed: () => reader.toggleDataSaver(),
                  ),
                  // Menú de tema de fondo
                  PopupMenuButton<ReaderTheme>(
                    icon: const Icon(Icons.palette_outlined, color: Colors.white70, size: 20),
                    color: const Color(0xFF222222),
                    onSelected: (theme) => reader.setTheme(theme),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: ReaderTheme.oledBlack,
                        child: Text('Negro OLED (Ahorro Batería)'),
                      ),
                      PopupMenuItem(
                        value: ReaderTheme.darkGray,
                        child: Text('Gris Oscuro'),
                      ),
                      PopupMenuItem(
                        value: ReaderTheme.sepia,
                        child: Text('Sepia Nocturno'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Barra Inferior (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: reader.showOverlay ? 0 : -140,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
                left: 14,
                right: 14,
              ),
              color: Colors.black.withValues(alpha: 0.92),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Control deslizante de página y navegación de capítulos
                  if (reader.pageUrls.isNotEmpty)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 22),
                          tooltip: 'Capítulo Anterior',
                          onPressed: reader.hasPreviousChapter
                              ? () => reader.goToPreviousChapter()
                              : null,
                        ),
                        Text(
                          '${reader.currentPage + 1}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.deepPurpleAccent,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.deepPurpleAccent,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: reader.currentPage.toDouble().clamp(
                                    0.0,
                                    (reader.pageUrls.length - 1).toDouble(),
                                  ),
                              min: 0,
                              max: (reader.pageUrls.length - 1).toDouble(),
                              onChanged: (val) {
                                final page = val.round();
                                reader.setPage(page);
                                if (reader.mode != ReadingMode.webtoonVertical) {
                                  _pageController.jumpToPage(page);
                                }
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${reader.pageUrls.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, color: Colors.white70, size: 22),
                          tooltip: 'Siguiente Capítulo',
                          onPressed: reader.hasNextChapter
                              ? () => reader.goToNextChapter()
                              : null,
                        ),
                      ],
                    ),

                  // Selector de Modos de Lectura
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeButton(
                        reader: reader,
                        mode: ReadingMode.webtoonVertical,
                        icon: Icons.view_day_outlined,
                        label: 'Webtoon',
                      ),
                      _buildModeButton(
                        reader: reader,
                        mode: ReadingMode.mangaRTL,
                        icon: Icons.chrome_reader_mode_outlined,
                        label: 'Manga (RTL)',
                      ),
                      _buildModeButton(
                        reader: reader,
                        mode: ReadingMode.comicLTR,
                        icon: Icons.menu_book_outlined,
                        label: 'Cómic (LTR)',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required ReaderProvider reader,
    required ReadingMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = reader.mode == mode;
    return InkWell(
      onTap: () => reader.setReadingMode(mode),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurpleAccent : Colors.white60,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.deepPurpleAccent : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderContent(ReaderProvider reader) {
    if (reader.pageUrls.isEmpty) return const SizedBox();

    // Modo 1: Webtoon / Manhwa (Desplazamiento Vertical Continuo)
    if (reader.mode == ReadingMode.webtoonVertical) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => reader.toggleOverlay(),
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.5,
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            // ignore: deprecated_member_use
            cacheExtent: 600,
            itemCount: reader.pageUrls.length + 1,
            itemBuilder: (context, index) {
              // Tarjeta de fin de capítulo
              if (index == reader.pageUrls.length) {
                return _buildEndOfChapterCard(reader);
              }
              return OptimizedImage(
                imageUrl: reader.pageUrls[index],
                fit: BoxFit.fitWidth,
              );
            },
          ),
        ),
      );
    }

    // Modo 2 y 3: Horizontal Paginado (Manga RTL y Cómic LTR) con navegación por zonas táctiles
    final isRTL = reader.mode == ReadingMode.mangaRTL;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              reverse: isRTL,
              itemCount: reader.pageUrls.length,
              onPageChanged: (index) => reader.setPage(index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  child: Center(
                    child: OptimizedImage(
                      imageUrl: reader.pageUrls[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),

            // Zonas de toque táctil inteligentes
            // Izquierda (30%)
            Positioned(
              left: 0,
              top: 80,
              bottom: 80,
              width: constraints.maxWidth * 0.3,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (isRTL) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),

            // Centro (40%) -> Menú
            Positioned(
              left: constraints.maxWidth * 0.3,
              top: 80,
              bottom: 80,
              width: constraints.maxWidth * 0.4,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => reader.toggleOverlay(),
              ),
            ),

            // Derecha (30%)
            Positioned(
              right: 0,
              top: 80,
              bottom: 80,
              width: constraints.maxWidth * 0.3,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (isRTL) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEndOfChapterCard(ReaderProvider reader) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            '¡Has llegado al final de este capítulo!',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            reader.hasNextChapter
                ? 'Siguiente: ${reader.nextChapter?.displayName}'
                : 'Este es el último capítulo disponible actualmente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (reader.hasNextChapter)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continuar al Siguiente Capítulo'),
              onPressed: () => reader.goToNextChapter(),
            ),
        ],
      ),
    );
  }
}
