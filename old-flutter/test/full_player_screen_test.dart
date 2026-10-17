import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/canvas.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/features/canvas/providers/canvas_provider.dart';
import 'package:metmusic/features/canvas/ui/canvas_overlay.dart';
import 'package:metmusic/features/player/models/player_state.dart';
import 'package:metmusic/features/player/providers/player_provider.dart';
import 'package:metmusic/features/player/ui/full_player_screen.dart';
import 'package:metmusic/features/player/ui/player_artwork.dart';

/// Layout del player completo: modo estático en pantalla normal/chica y en
/// apaisado (sin desbordes), y modo canvas con el header flotando sobre el
/// vídeo. No se usan las acciones del controlador, sólo su estado.
class _FakePlayerController extends StateNotifier<MetPlayerState>
    implements PlayerController {
  _FakePlayerController() : super(_playing);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _track = Track(
  trackId: '424096050',
  title: 'Corazón',
  artist: 'Maluma',
  album: 'F.A.M.E',
  durationSeconds: 184,
);

const _playing = MetPlayerState(
  track: _track,
  playing: true,
  position: Duration(seconds: 66),
  duration: Duration(minutes: 3, seconds: 4),
);

ProviderContainer _container({bool withCanvas = false}) {
  return ProviderContainer(
    overrides: [
      playerProvider.overrideWith((ref) => _FakePlayerController()),
      currentTrackIsFavoriteProvider.overrideWithValue(false),
      if (withCanvas)
        canvasProvider.overrideWith(
          (ref, trackId) async => const CanvasMedia(
            url: 'https://example.com/canvas.mp4',
          ),
        ),
    ],
  );
}

/// Monta el player a tamaño [size] y deja correr los timers de arranque.
Future<void> _pumpPlayer(
  WidgetTester tester, {
  required Size size,
  bool withCanvas = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = _container(withCanvas: withCanvas);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: FullPlayerScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('modo estático en 390×844: header, info y pills', (tester) async {
    await _pumpPlayer(tester, size: const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('REPRODUCIENDO'), findsOneWidget);
    expect(find.text('MetMusic'), findsOneWidget);
    expect(find.text('Corazón'), findsOneWidget);
    expect(find.text('Maluma • F.A.M.E'), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('Cola'), findsOneWidget);
    expect(find.text('Letras'), findsOneWidget);
    expect(find.text('1:06'), findsOneWidget);
    expect(find.text('3:04'), findsOneWidget);

    // Sin canvas la portada va POR DEBAJO del header, en el flujo.
    final header = tester.getRect(find.text('REPRODUCIENDO'));
    final art = tester.getRect(find.byType(PlayerArtwork));
    expect(header.bottom, lessThanOrEqualTo(art.top));
  });

  testWidgets('pantalla chica 320×568: no desborda', (tester) async {
    await _pumpPlayer(tester, size: const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.byType(FullPlayerScreen), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
  });

  testWidgets('apaisado 812×375: sin portada y sin desbordes', (tester) async {
    await _pumpPlayer(tester, size: const Size(812, 375));

    expect(tester.takeException(), isNull);
    expect(find.byType(PlayerArtwork), findsNothing);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('REPRODUCIENDO'), findsOneWidget);
  });

  testWidgets('modo canvas: el header flota sobre el vídeo', (tester) async {
    await _pumpPlayer(tester, size: const Size(390, 844), withCanvas: true);

    expect(tester.takeException(), isNull);
    expect(find.byType(CanvasOverlay), findsOneWidget);

    // El arte base ocupa la caja de vídeo desde el borde superior y el
    // header se SUPERPONE: sus rectángulos se solapan (antes el header
    // terminaba donde empezaba el vídeo, sin solape).
    final header = tester.getRect(find.text('REPRODUCIENDO'));
    final art = tester.getRect(find.byType(PlayerArtwork));
    expect(header.top, lessThan(art.top + 60));
    expect(header.bottom, greaterThan(art.top));
  });
}
