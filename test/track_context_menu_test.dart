import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/features/player/providers/radio_provider.dart';
import 'package:metmusic/features/player/ui/track_context_menu.dart';

/// Menú de contexto de una pista: lista las acciones, la estación devuelve
/// `TrackAction.radio` al tocarla y no se abre si la pista ya se marcó como
/// sin radio (404 previo).
void main() {
  const track = Track(
    trackId: '424096050',
    title: 'One More Time',
    artist: 'Daft Punk',
  );

  /// Monta el botón que abre el menú como hoja modal (igual que
  /// `openTrackContextMenu`) y completa [closed] con la acción elegida.
  Future<void> pumpMenuHost(
    WidgetTester tester,
    Completer<TrackAction?> closed,
  ) {
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
                    builder: (_) => const TrackContextMenu(
                      track: track,
                      actions: [TrackAction.radio],
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

  testWidgets('lista la estación de la pista y devuelve la acción',
      (tester) async {
    final closed = Completer<TrackAction?>();
    await pumpMenuHost(tester, closed);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(TrackContextMenu), findsOneWidget);
    expect(find.text('One More Time'), findsOneWidget);
    expect(find.text('Estación de Daft Punk'), findsOneWidget);
    expect(find.text('Mezcla de pistas parecidas'), findsOneWidget);
    expect(find.byIcon(LucideIcons.radio), findsOneWidget);

    await tester.tap(find.text('Estación de Daft Punk'));
    await tester.pumpAndSettle();

    expect(await closed.future, TrackAction.radio);
  });

  testWidgets('pista sin radio → no abre nada', (tester) async {
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

    expect(find.byType(TrackContextMenu), findsNothing);
  });
}
