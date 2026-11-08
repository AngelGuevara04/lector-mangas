# 📖 MangaFlow - Lector de Mangas, Manhwas y Cómics Ultra Ligero

Aplicación móvil ultra ligera desarrollada en **Flutter**, diseñada especialmente para **teléfonos de gama baja o antiguos** y equipada con un motor de búsqueda y lectura en línea en tiempo real sin descargas previas.

---

## ✨ Características

* **🌐 Búsqueda y Lectura en Línea:** Integrado con la red abierta de **MangaDex**. Encuentra miles de mangas, manhwas y manhuas al instante.
* **⚡ Ultra Optimizado para Gama Baja:**
  * **Consumo de RAM mínimo:** Límite estricto de memoria en caché de imágenes (45 MB) para evitar cierres repentinos (*Out-Of-Memory*).
  * **Downsampling dinámico:** Las imágenes se decodifican al ancho de la pantalla del dispositivo, reduciendo el peso en RAM más de un 85%.
  * **Modo Ultra Ligero (Data Saver):** Transmisión de imágenes en formato WebP comprimido (ahorra hasta 70% de datos móviles).
  * **Reciclado de memoria:** Las páginas que salen de pantalla se liberan inmediatamente de la RAM.
* **📱 3 Modos de Lectura Integrados:**
  * 📜 **Modo Webtoon (Vertical Continuo):** Ideal para Manhwas coreanos sin cortes entre páginas.
  * 📖 **Modo Manga (Horizontal RTL):** Paginación japonesa tradicional de derecha a izquierda.
  * 📘 **Modo Cómic (Horizontal LTR):** Paginación occidental de izquierda a derecha.
* **🔍 Zoom Táctil y Temas OLED:** Soporte de *pinch-to-zoom* con doble toque y selección de temas (Negro OLED, Gris Oscuro, Sepia).
* **📚 Biblioteca, Historial y Continuar Leyendo:** Guarda tus obras favoritas y continúa exactamente en el capítulo y página donde te quedaste.
* **🔄 Actualizador Remoto:** Comprobador de nuevas versiones conectado directamente a GitHub Releases.
* **💡 Buzón de Sugerencias:** Envío directo de solicitudes de mejoras a GitHub Issues.

---

## 📂 Estructura del Repositorio

* `MangaFlow.apk`: Instalador listo para cualquier dispositivo Android.
* `desarrollo/`: Contiene el código fuente completo en Flutter, dependencias y configuración de compilación de Android.
* `desarrollo/compilar_apk.bat`: Script automatizado para compilar el proyecto y colocar el APK en la raíz.

---

## 📲 Instalación en Android

Descarga el archivo APK directamente desde la pestaña de **[Releases](../../releases)** o compila tu propia versión desde la carpeta `desarrollo`.
