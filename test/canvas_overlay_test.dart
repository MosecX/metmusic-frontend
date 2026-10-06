import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/utils/image_utils.dart';
import 'package:metmusic/features/canvas/ui/canvas_overlay.dart';

void main() {
  group('CanvasOverlay.fittedSize', () {
    // Canvas de Spotify: verticales (720x1280 → 0.5625).
    const portrait = 720 / 1280;
    // Canvas de Apple Music: cuadrados (768x768 → 1.0).
    const square = 1.0;
    // Vídeo horizontal genérico.
    const landscape = 1280 / 720;

    test('cover llena la portada cuadrada con un canvas vertical', () {
      final size = CanvasOverlay.fittedSize(
        const Size(300, 300),
        portrait,
        BoxFit.cover,
      );
      // Llena el ancho y sobresale en altura (se recorta).
      expect(size.width, 300);
      expect(size.height, greaterThan(300));
      expect(size.width.roundToDouble(), size.width);
    });

    test('cover llena la pantalla vertical con un canvas vertical', () {
      final size = CanvasOverlay.fittedSize(
        const Size(1080, 2340),
        portrait,
        BoxFit.cover,
      );
      expect(size.height, 2340);
      expect(size.width, greaterThan(1080));
    });

    test('cover recorta un vídeo horizontal dentro de la portada', () {
      final size = CanvasOverlay.fittedSize(
        const Size(300, 300),
        landscape,
        BoxFit.cover,
      );
      expect(size.height, 300);
      expect(size.width, greaterThan(300));
    });

    test('contain deja ver el artwork por los costados', () {
      final size = CanvasOverlay.fittedSize(
        const Size(300, 300),
        portrait,
        BoxFit.contain,
      );
      expect(size.height, 300);
      expect(size.width, lessThan(300));
    });

    test('un canvas cuadrado cubre la portada sin deformarse', () {
      final size = CanvasOverlay.fittedSize(
        const Size(300, 300),
        square,
        BoxFit.cover,
      );
      expect(size, const Size(300, 300));
    });

    test('fill ocupa la caja entera', () {
      expect(
        CanvasOverlay.fittedSize(const Size(320, 240), portrait, BoxFit.fill),
        const Size(320, 240),
      );
    });

    test('cajas o aspectos inválidos no generan tamaños raros', () {
      expect(CanvasOverlay.fittedSize(Size.zero, portrait, BoxFit.cover),
          Size.zero);
      expect(CanvasOverlay.fittedSize(const Size(300, 300), 0, BoxFit.cover),
          Size.zero);
      expect(CanvasOverlay.fittedSize(const Size(300, 300), double.nan,
          BoxFit.cover), Size.zero);
    });
  });

  group('ImageUtils.artistImageUrl', () {
    test('convierte el UUID con guiones en ruta del CDN (guiones → /)', () {
      expect(
        ImageUtils.artistImageUrl('65d23ddc-7b3b-4b17-bc84-b02832ddc204'),
        'https://resources.tidal.com/images/65d23ddc/7b3b/4b17/bc84/'
        'b02832ddc204/750x750.jpg',
      );
    });

    test('acepta la ruta ya separada por barras', () {
      expect(
        ImageUtils.artistImageUrl(
            '65d23ddc/7b3b/4b17/bc84/b02832ddc204'),
        'https://resources.tidal.com/images/65d23ddc/7b3b/4b17/bc84/'
        'b02832ddc204/750x750.jpg',
      );
    });

    test('respeta una URL absoluta del backend', () {
      const url =
          'https://resources.tidal.com/images/65d23ddc/7b3b/4b17/bc84/'
          'b02832ddc204/1280x1280.jpg';
      expect(ImageUtils.artistImageUrl(url), url);
    });

    test('sin imagen no inventa una URL', () {
      expect(ImageUtils.artistImageUrl(''), '');
    });
  });
}
