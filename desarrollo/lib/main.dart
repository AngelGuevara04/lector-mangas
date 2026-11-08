import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'providers/manga_provider.dart';
import 'providers/reader_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar almacenamiento ultraligero
  await StorageService().init();

  // OPTIMIZACIÓN CLAVE PARA GAMA BAJA / DISPOSITIVOS ANTIGUOS:
  // Reducir la caché de imágenes de Flutter en RAM a un máximo estricto de 45 MB y 30 imágenes.
  // El valor por defecto de Flutter puede superar los 150 MB y provocar cierres (OOM) en teléfonos con 1GB-2GB de RAM.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 45 * 1024 * 1024; // 45 MB max
  PaintingBinding.instance.imageCache.maximumSize = 30; // 30 imágenes decoded

  // Barra de estado y navegación translúcida para lectura inmersiva
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF181818),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MangaFlowApp());
}

class MangaFlowApp extends StatelessWidget {
  const MangaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MangaProvider()),
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
      ],
      child: MaterialApp(
        title: 'MangaFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: Colors.deepPurpleAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            secondary: Colors.purpleAccent,
            surface: Color(0xFF1E1E1E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF181818),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
