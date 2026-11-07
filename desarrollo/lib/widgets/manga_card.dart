import 'package:flutter/material.dart';
import '../models/manga.dart';
import 'optimized_image.dart';
import '../screens/manga_detail_screen.dart';

class MangaCard extends StatelessWidget {
  final Manga manga;

  const MangaCard({super.key, required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MangaDetailScreen(manga: manga),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada con etiqueta de tipo
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: manga.coverUrl != null
                      ? SizedBox.expand(
                          child: OptimizedImage(
                            imageUrl: manga.coverUrl!,
                            memCacheWidth: 320, // Portadas ligeras en memoria
                          ),
                        )
                      : Container(
                          color: const Color(0xFF2C2C2C),
                          child: const Center(
                            child: Icon(Icons.menu_book, color: Colors.white24, size: 40),
                          ),
                        ),
                ),
                // Badge con tipo (Manhwa, Manga, Manhua)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      manga.comicType.split(' ').first,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Título
          Text(
            manga.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
