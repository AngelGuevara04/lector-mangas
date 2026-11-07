import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../providers/reader_provider.dart';
import '../widgets/optimized_image.dart';

class ReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final bool isWebtoon;

  const ReaderScreen({
    super.key,
    required this.chapter,
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
      reader.loadChapter(widget.chapter);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reader = Provider.of<ReaderProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
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
                      onPressed: () => reader.loadChapter(widget.chapter),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => reader.toggleOverlay(),
              child: _buildReaderContent(reader),
            ),

          // Barra Superior (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            top: reader.showOverlay ? 0 : -90,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 6,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              color: Colors.black.withValues(alpha: 0.85),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.chapter.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
                ],
              ),
            ),
          ),

          // Barra Inferior (Overlay)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            bottom: reader.showOverlay ? 0 : -130,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 8,
                top: 8,
                left: 16,
                right: 16,
              ),
              color: Colors.black.withValues(alpha: 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Control deslizante de página
                  if (reader.pageUrls.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          '${reader.currentPage + 1}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                                if (reader.mode == ReadingMode.webtoonVertical) {
                                  // Salto aproximado en vertical
                                  // Para precisión se puede calcular altura
                                } else {
                                  _pageController.jumpToPage(page);
                                }
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${reader.pageUrls.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                        label: 'Webtoon (Vertical)',
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
    if (reader.pageUrls.isEmpty) {
      return const SizedBox();
    }

    // Modo 1: Webtoon / Manhwa (Desplazamiento Vertical Continuo)
    if (reader.mode == ReadingMode.webtoonVertical) {
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 3.5,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          // ignore: deprecated_member_use
          cacheExtent: 600,
          itemCount: reader.pageUrls.length,
          itemBuilder: (context, index) {
            return OptimizedImage(
              imageUrl: reader.pageUrls[index],
              fit: BoxFit.fitWidth,
            );
          },
        ),
      );
    }

    // Modo 2 y 3: Horizontal Paginado (Manga RTL y Cómic LTR)
    final isRTL = reader.mode == ReadingMode.mangaRTL;

    return PageView.builder(
      controller: _pageController,
      reverse: isRTL,
      itemCount: reader.pageUrls.length,
      onPageChanged: (index) {
        reader.setPage(index);
      },
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
    );
  }
}
