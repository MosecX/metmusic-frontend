import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/features/player/providers/radio_provider.dart';
import 'package:metmusic/features/player/ui/track_context_menu.dart';

/// Menú de contexto de una pista: encabezado con la portada, la lista de
/// acciones (estación, álbum, artista, metadatos) y el caso en que la pista
/// ya se marcó como sin radio (404 previo).
void main() {
  const track = Track(
    trackId: '424096050',
    title: 'One More Time',
    artist: 'Daft Punk',
  );

  const fullTrack = Track(
    trackId: '424096050',
    title: 'One More Time',
    artist: 'Daft Punk',
    album: 'Discovery',
    albumId: '302127',
    artistId: '14885395',
  );

  /// Monta el botón que abre [openTrackContextMenu] como hoja modal y
  /// completa [closed] con la acción elegida.
  Future<void> pumpMenuHost(
    WidgetTester tester,
    Completer<TrackAction?> closed, {
    Track forTrack = track,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final action = await showModalBottomSheet<TrackAction>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TrackContextMenu(
                      track: forTrack,
                      actions: const [TrackAction.radio],
                    ),
                  );
                  if (!closed.isCompleted) closed.complete(action);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('lista la estación con su portada y devuelve la acción',
      (tester) async {
    final closed = Completer<TrackAction?>();
    await pumpMenuHost(tester, closed);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(TrackContextMenu), findsOneWidget);
    // Encabezado: la portada del track (sin miniatura → nota musical).
    expect(find.byIcon(LucideIcons.music), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Daft Punk'), findsOneWidget);

    expect(find.byIcon(LucideIcons.radio), findsOneWidget);
    expect(find.text('Estación: One More Time'), findsOneWidget);
    expect(find.text('Reproduce la mezcla y abre su página'), findsOneWidget);

    await tester.tap(find.text('Estación: One More Time'));
    await tester.pumpAndSettle();

    expect(await closed.future, TrackAction.radio);
  });

  testWidgets('ofrece álbum, artista y metadatos cuando la pista trae los ids',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrackContextMenu(
            track: fullTrack,
            actions: [
              TrackAction.album,
              TrackAction.artist,
              TrackAction.metadata,
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.album), findsOneWidget);
    expect(find.text('Ir al álbum'), findsOneWidget);
    expect(find.text('Discovery'), findsOneWidget);

    expect(find.byIcon(LucideIcons.userRound), findsOneWidget);
    expect(find.text('Ir al artista'), findsOneWidget);

    expect(find.byIcon(LucideIcons.info), findsOneWidget);
    expect(find.text('Metadatos'), findsOneWidget);
    expect(find.text('ISRC, BPM, calidad, copyright…'), findsOneWidget);
  });

  testWidgets('toca "Ir al álbum" y devuelve la acción', (tester) async {
    final closed = Completer<TrackAction?>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final action = await showModalBottomSheet<TrackAction>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const TrackContextMenu(
                      track: fullTrack,
                      actions: [TrackAction.album, TrackAction.metadata],
                    ),
                  );
                  if (!closed.isCompleted) closed.complete(action);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir al álbum'));
    await tester.pumpAndSettle();

    expect(await closed.future, TrackAction.album);
  });

  testWidgets('pista sin radio → abre el menú sin la estación', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: () {
                    ref.read(radioUnsupportedProvider.notifier).state = {
                      track.trackId,
                    };
                    openTrackContextMenu(context, ref, track);
                  },
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(TrackContextMenu), findsOneWidget);
    expect(find.byIcon(LucideIcons.radio), findsNothing);
    expect(find.byIcon(LucideIcons.info), findsOneWidget);
  });
}
