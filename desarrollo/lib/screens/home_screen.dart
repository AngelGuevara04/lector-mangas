import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/manga_provider.dart';
import '../widgets/manga_card.dart';
import '../widgets/optimized_image.dart';
import '../services/storage_service.dart';
import '../services/update_service.dart';
import 'manga_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  int _libraryTab = 0; // 0 = Favoritos, 1 = Historial
  bool _isCheckingUpdate = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildExploreTab(),
          _buildLibraryTab(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF181818),
        indicatorColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Provider.of<MangaProvider>(context, listen: false).loadHistory();
            Provider.of<MangaProvider>(context, listen: false).loadFavorites();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.explore, color: Colors.deepPurpleAccent),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.collections_bookmark, color: Colors.deepPurpleAccent),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.tune, color: Colors.deepPurpleAccent),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  // ========================================================
  // PESTAÑA 1: EXPLORAR & BÚSQUEDA AVANZADA EN LÍNEA
  // ========================================================
  Widget _buildExploreTab() {
    final mangaProvider = Provider.of<MangaProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          // Barra de búsqueda en línea
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar cualquier manga, manhwa o cómic...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          mangaProvider.search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF202020),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => mangaProvider.search(val),
            ),
          ),

          // Filtros de categoría rápida (Tipo de obra)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all', mangaProvider),
                const SizedBox(width: 6),
                _buildFilterChip('Manhwa (Corea)', 'ko', mangaProvider),
                const SizedBox(width: 6),
                _buildFilterChip('Manga (Japón)', 'ja', mangaProvider),
                const SizedBox(width: 6),
                _buildFilterChip('Manhua (China)', 'zh', mangaProvider),
              ],
            ),
          ),

          // Barra de Ordenamiento y Estado (En emisión / Finalizados)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Orden
                DropdownButton<String>(
                  value: mangaProvider.sortOrder,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.sort, color: Colors.white54, size: 16),
                  items: const [
                    DropdownMenuItem(value: 'popular', child: Text('🔥 Más Populares')),
                    DropdownMenuItem(value: 'rating', child: Text('⭐ Mejor Valorados')),
                    DropdownMenuItem(value: 'latest', child: Text('🕒 Recientes')),
                  ],
                  onChanged: (val) {
                    if (val != null) mangaProvider.setSortOrder(val);
                  },
                ),

                // Filtro de Estado
                DropdownButton<String>(
                  value: mangaProvider.statusFilter,
                  dropdownColor: const Color(0xFF222222),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_list, color: Colors.white54, size: 16),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos los estados')),
                    DropdownMenuItem(value: 'ongoing', child: Text('En emisión')),
                    DropdownMenuItem(value: 'completed', child: Text('Finalizados')),
                  ],
                  onChanged: (val) {
                    if (val != null) mangaProvider.setStatusFilter(val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Grilla de resultados
          Expanded(
            child: mangaProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                    ),
                  )
                : mangaProvider.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                mangaProvider.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurpleAccent,
                                ),
                                onPressed: () => mangaProvider.fetchInitial(),
                                child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : mangaProvider.items.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron resultados.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => mangaProvider.search(_searchCtrl.text),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(14),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.58,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: mangaProvider.items.length,
                              itemBuilder: (context, index) {
                                return MangaCard(manga: mangaProvider.items[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String key, MangaProvider provider) {
    final isSelected = provider.selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepPurpleAccent,
      backgroundColor: const Color(0xFF202020),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide.none,
      onSelected: (_) => provider.setCategory(key),
    );
  }

  // ========================================================
  // PESTAÑA 2: BIBLIOTECA & CONTINUAR LEYENDO (HISTORIAL)
  // ========================================================
  Widget _buildLibraryTab() {
    final mangaProvider = Provider.of<MangaProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          // Selector de vista: Favoritos o Historial
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.favorite, size: 16),
                        label: Text('Favoritos', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.history, size: 16),
                        label: Text('Continuar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_libraryTab},
                    onSelectionChanged: (set) {
                      setState(() => _libraryTab = set.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.deepPurpleAccent;
                        }
                        return const Color(0xFF202020);
                      }),
                      foregroundColor: const WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _libraryTab == 0
                ? _buildFavoritesView(mangaProvider)
                : _buildHistoryView(mangaProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesView(MangaProvider mangaProvider) {
    final favs = mangaProvider.favorites;
    if (favs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_bookmark_outlined, color: Colors.white24, size: 56),
            SizedBox(height: 12),
            Text(
              'Aún no tienes mangas en favoritos.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Toca el corazón en la ficha de cualquier manga.',
              style: TextStyle(color: Colors.white38, fontSize: 11.5),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: favs.length,
      itemBuilder: (context, index) => MangaCard(manga: favs[index]),
    );
  }

  Widget _buildHistoryView(MangaProvider mangaProvider) {
    final history = mangaProvider.history;
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: Colors.white24, size: 56),
            SizedBox(height: 12),
            Text(
              'No hay historial de lectura reciente.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            SizedBox(height: 4),
            Text(
              'Cuando leas un capítulo aparecerá aquí.',
              style: TextStyle(color: Colors.white38, fontSize: 11.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 64,
                child: entry.coverUrl != null
                    ? OptimizedImage(imageUrl: entry.coverUrl!, memCacheWidth: 150)
                    : Container(color: Colors.grey[850]),
              ),
            ),
            title: Text(
              entry.mangaTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Cap. ${entry.chapterNum} • Pág. ${entry.pageIndex + 1} de ${entry.totalPages}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: entry.totalPages > 0 ? (entry.pageIndex + 1) / entry.totalPages : 0,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                  minHeight: 3,
                ),
              ],
            ),
            trailing: const Icon(Icons.play_circle_fill, color: Colors.deepPurpleAccent, size: 28),
            onTap: () async {
              // Carga los detalles del manga y abre la ficha
              final manga = await mangaProvider.getManga(entry.mangaId);
              if (manga != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MangaDetailScreen(manga: manga)),
                );
              }
            },
          ),
        );
      },
    );
  }

  // ========================================================
  // PESTAÑA 3: AJUSTES, ACTUALIZACIONES Y SOLICITUD DE MEJORAS
  // ========================================================
  Widget _buildSettingsTab() {
    final storage = StorageService();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ajustes del Sistema',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Amors Reader ${UpdateService.currentVersion}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 16),

          // SECCIÓN 1: ACTUALIZACIONES REMOTAS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurpleAccent.withValues(alpha: 0.25),
                  const Color(0xFF1E1E1E),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.system_update, color: Colors.deepPurpleAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Actualización Remota en GitHub',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Comprueba si hay una nueva versión del APK en el repositorio oficial.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(_isCheckingUpdate ? 'Comprobando...' : 'Buscar Actualización'),
                    onPressed: _isCheckingUpdate ? null : _handleCheckUpdate,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // SECCIÓN 2: CUADRO DE SOLICITUD DE MEJORAS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Buzón de Mejoras y Sugerencias',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '¿Falta algún manga o función? Envía tu solicitud directamente al GitHub del proyecto para que podamos programarla.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    side: const BorderSide(color: Colors.amberAccent),
                  ),
                  icon: const Icon(Icons.add_comment, size: 18),
                  label: const Text('Solicitar una Mejora o Reportar Error'),
                  onPressed: () => _showFeedbackDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // SECCIÓN 3: RENDIMIENTO Y GAMA BAJA
          const Text(
            'Rendimiento y Memoria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo Ultra Ligero (Data Saver)', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Usa WebP comprimido de MangaDex. Ahorra 70% de RAM y datos móviles.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            value: storage.getDataSaver(),
            activeThumbColor: Colors.deepPurpleAccent,
            onChanged: (val) async {
              await storage.setDataSaver(val);
              setState(() {});
            },
          ),
          const Divider(color: Colors.white12),

          // Botón limpiar caché
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Limpiar Memoria Caché', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Libera espacio borrando imágenes temporales de capítulos leídos.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 0.8),
              ),
              child: const Text('Liberar', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                await storage.clearImageCache();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caché de imágenes liberada con éxito.')),
                );
              },
            ),
          ),
          const Divider(color: Colors.white12),

          // Idioma preferido
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Idioma Prioritario', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Idioma al mostrar capítulos.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: DropdownButton<String>(
              value: storage.getLanguagePreference(),
              dropdownColor: const Color(0xFF222222),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('🇲🇽 Español')),
                DropdownMenuItem(value: 'en', child: Text('🇬🇧 Inglés')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await storage.setLanguagePreference(val);
                  setState(() {});
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Comprobación de Actualización ---
  Future<void> _handleCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    final info = await UpdateService.checkForUpdate();
    setState(() => _isCheckingUpdate = false);

    if (!mounted) return;

    if (info.hasUpdate) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text('¡Nueva Versión ${info.latestVersion}!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Versión actual: ${info.currentVersion}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 10),
              const Text('Novedades:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(info.changelog, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Más tarde', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              onPressed: () {
                Navigator.pop(context);
                if (info.apkDownloadUrl != null) {
                  UpdateService.openUrl(info.apkDownloadUrl!);
                }
              },
              child: const Text('Descargar APK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya cuentas con la versión más reciente (v1.0.0).')),
      );
    }
  }

  // --- Modal de Buzón de Mejoras / GitHub Issues ---
  void _showFeedbackDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Mejora';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Buzón de Mejoras y Sugerencias',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Las solicitudes se registran en el repositorio de GitHub para programarlas en la próxima actualización.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // Selector de categoría
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF282828),
                    decoration: InputDecoration(
                      labelText: 'Tipo de Solicitud',
                      filled: true,
                      fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Mejora', child: Text('Nueva Función / Mejora')),
                      DropdownMenuItem(value: 'Catálogo', child: Text('Sugerencia de Manga / Fuente')),
                      DropdownMenuItem(value: 'Error', child: Text('Reporte de Error o Bug')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Título
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Título breve (ej. Modo oscuro sepia, más mangas)',
                      filled: true,
                      fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Descripción detallada
                  TextField(
                    controller: descCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Explica con detalle qué te gustaría ver en la app...',
                      filled: true,
                      fillColor: const Color(0xFF252525),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Botón Enviar a GitHub
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar Solicitud a GitHub'),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        UpdateService.openFeatureRequest(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          category: category,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
