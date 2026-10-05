import '../models/thumbnail.dart';

/// Utilidades para seleccionar la mejor imagen disponible.
class ImageUtils {
  ImageUtils._();

  /// Devuelve la URL de la miniatura cuyo ancho se acerque más a [targetSize].
  static String bestThumbnail(List<Thumbnail> thumbnails, int targetSize) {
    if (thumbnails.isEmpty) return '';
    final sorted = [...thumbnails]
      ..sort((a, b) => (a.width ?? 0).compareTo(b.width ?? 0));
    for (final t in sorted) {
      if ((t.width ?? 0) >= targetSize) return t.url;
    }
    return sorted.last.url;
  }

  /// Miniatura para listas (48–64 dp).
  static String listThumbnail(List<Thumbnail> thumbnails) =>
      bestThumbnail(thumbnails, 160);

  /// Miniatura para cards y headers.
  static String cardThumbnail(List<Thumbnail> thumbnails) =>
      bestThumbnail(thumbnails, 640);

  /// Artwork grande para el reproductor.
  static String largeArtwork(List<Thumbnail> thumbnails) =>
      bestThumbnail(thumbnails, 1280);

  /// Tamaño de recurso para `cached_network_image`.
  static int cacheWidth(int logicalSize, double devicePixelRatio) =>
      (logicalSize * devicePixelRatio).round();
}
