import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Componente de imagen altamente optimizado para teléfonos de gama baja
/// Evita fugas de memoria (OOM) y sobrecalentamiento limitando el tamaño en RAM
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Si no se especifica ancho en memoria, limitamos por defecto al ancho de la pantalla del dispositivo
    // Esto es el secreto para que los cómics en 4K no congelen teléfonos de 1GB/2GB de RAM
    final screenPixelWidth = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round();
    final targetMemWidth = memCacheWidth ?? screenPixelWidth.clamp(360, 1080);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: targetMemWidth,
      httpHeaders: const {
        'User-Agent': 'MangaFlow/1.0.2 (https://github.com/AngelGuevara04/lector-mangas)',
      },
      placeholder: (context, url) => Container(
        color: const Color(0xFF1E1E1E),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFF252525),
        padding: const EdgeInsets.all(8),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.white38, size: 28),
              SizedBox(height: 4),
              Text(
                'Error al cargar',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
