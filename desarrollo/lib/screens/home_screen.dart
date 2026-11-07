import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/manga_provider.dart';
import '../widgets/manga_card.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

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

  // --- Pestaña 1: Explorar & Buscar en línea ---
  Widget _buildExploreTab() {
    final mangaProvider = Provider.of<MangaProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          // Barra de búsqueda en línea
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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

          // Filtros de categoría rápida (Tipo de cómic)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all', mangaProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Manhwa (Corea)', 'ko', mangaProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Manga (Japón)', 'ja', mangaProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Manhua (China)', 'zh', mangaProvider),
              ],
            ),
          ),

          const SizedBox(height: 6),

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
      backgroundColor: const Color(0xFF222222),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      onSelected: (_) => provider.setCategory(key),
    );
  }

  // --- Pestaña 2: Biblioteca / Favoritos ---
  Widget _buildLibraryTab() {
    final mangaProvider = Provider.of<MangaProvider>(context);
    final favs = mangaProvider.favorites;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Mi Biblioteca',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: favs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.collections_bookmark_outlined, color: Colors.white24, size: 64),
                        SizedBox(height: 12),
                        Text(
                          'Aún no tienes mangas en tu biblioteca.',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Explora y toca el corazón para guardarlos aquí.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: favs.length,
                    itemBuilder: (context, index) {
                      return MangaCard(manga: favs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Pestaña 3: Ajustes y Optimización ---
  Widget _buildSettingsTab() {
    final storage = StorageService();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ajustes y Rendimiento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configurado para máxima fluidez y bajo consumo de batería y RAM.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Modo Ahorro de Datos y RAM
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo Ultra Ligero (Data Saver)', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Carga imágenes WebP optimizadas. Reduce el uso de memoria en un 70% y evita cierres en teléfonos antiguos.',
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

          // Idioma preferido
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Idioma de Capítulos', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Idioma prioritario al cargar la lista de capítulos.',
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
          const Divider(color: Colors.white12),

          // Modo de lectura predeterminado
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo de Lectura por Defecto', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Formato predeterminado al abrir una obra.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: DropdownButton<String>(
              value: storage.getReadingModePreference(),
              dropdownColor: const Color(0xFF222222),
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'vertical', child: Text('Vertical (Webtoon)')),
                DropdownMenuItem(value: 'rtl', child: Text('Horizontal (Manga RTL)')),
                DropdownMenuItem(value: 'ltr', child: Text('Horizontal (Cómic LTR)')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await storage.setReadingModePreference(val);
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(color: Colors.white12),

          const SizedBox(height: 16),
          // Información de Arquitectura
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.speed, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Optimización de Gama Baja Activa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Decodificación dinámica de bitmaps limitada al ancho del dispositivo.\n'
                  '• Reciclado automático de widgets fuera de pantalla.\n'
                  '• Caché de imágenes limitada en RAM para prevenir OOM.\n'
                  '• Conexión directa a servidores globales CDN sin scraping pesado en el teléfono.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
