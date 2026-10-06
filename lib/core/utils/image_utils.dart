import '../models/thumbnail.dart';

/// Utilidades para seleccionar la mejor imagen disponible.
class ImageUtils {
  ImageUtils._();

  /// Devuelve la URL de la miniatura cuyo ancho se acerque más a [targetSize].
  static String bestThumbnail(List<Thumbnail> thumbnails, int targetSize) {
    // Las entradas sin URL o sin ancho no sirven para decidir: se descartan
    // antes de ordenar para no arrastrar un ancho `null` (que sortea como 0).
    final usable =
        thumbnails.where((t) => t.url.isNotEmpty).toList(growable: false);
    if (usable.isEmpty) return '';

    final sized =
        usable.where((t) => (t.width ?? 0) > 0).toList(growable: false);
    if (sized.isEmpty) {
      // El backend no manda ancho: no se puede elegir por tamaño, se usa la
      // última (en estos catálogos viene de mayor a menor).
      return usable.last.url;
    }

    final sorted = [...sized]
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

  /// Miniatura de artista.
  ///
  /// El catálogo sólo publica imágenes de artista hasta 750x750: pedir más
  /// devuelve un 404 y el artwork no aparece nunca.
  static String artistThumbnail(List<Thumbnail> thumbnails) =>
      bestThumbnail(thumbnails, 750);

  /// Artwork grande para el reproductor.
  static String largeArtwork(List<Thumbnail> thumbnails) =>
      bestThumbnail(thumbnails, 750);

  /// Tamaño de recurso para `cached_network_image`.
  static int cacheWidth(int logicalSize, double devicePixelRatio) =>
      (logicalSize * devicePixelRatio).round();
}
