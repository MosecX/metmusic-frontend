import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/lyrics.dart';
import 'package:metmusic/core/utils/lyrics_timeline.dart';
import 'package:metmusic/features/player/ui/lyrics/lyrics_gap.dart';
import 'package:metmusic/features/player/ui/lyrics/lyrics_line.dart';

/// Contrato de render de la hoja de letras: escalera de distancia, karaoke
/// por wipe (dos capas + ShaderMask) con su guarda de reflow, y los puntos
/// de los huecos instrumentales.
void main() {
  SyncedLine line({bool brokenWords = false}) {
    return SyncedLine(
      timeMs: 1000,
      durationMs: 4000,
      text: 'hola mundo',
      words: brokenWords
          ? const [
              SyncedWord(timeMs: 1000, durationMs: 2000, text: 'hola'),
              SyncedWord(timeMs: 3000, durationMs: 2000, text: 'mundo'),
            ]
          : const [
              SyncedWord(timeMs: 1000, durationMs: 2000, text: 'hola '),
              SyncedWord(timeMs: 3000, durationMs: 2000, text: 'mundo'),
            ],
    );
  }

  Finder lineChild(Type type) => find.descendant(
        of: find.byType(LyricsLine),
        matching: find.byType(type),
      );

  Finder gapChild(Type type) => find.descendant(
        of: find.byType(LyricsGapDots),
        matching: find.byType(type),
      );

  Future<void> pumpLine(
    WidgetTester tester, {
    bool lit = false,
    int distance = 1,
    LyricsSyncLevel level = LyricsSyncLevel.word,
    bool brokenWords = false,
    int positionMs = 2000,
    bool visualizer = false,
    void Function()? onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LyricsLine(
            line: line(brokenWords: brokenWords),
            lit: lit,
            distance: distance,
            level: level,
            positionMs: positionMs,
            visualizer: visualizer,
            landscape: false,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('escalera de distancia', () {
    testWidgets('la activa va a opacidad 1 y escala 1', (tester) async {
      await pumpLine(tester, lit: true, distance: 0);
      final opacity = tester.widget<AnimatedOpacity>(
        lineChild(AnimatedOpacity),
      );
      final scale = tester.widget<AnimatedScale>(lineChild(AnimatedScale));
      expect(opacity.opacity, 1.0);
      expect(scale.scale, 1.0);
      expect(opacity.duration, const Duration(milliseconds: 300));
    });

    testWidgets('las inactivas bajan a 0.8 / 0.46 y escala 0.98',
        (tester) async {
      await pumpLine(tester, distance: 1);
      expect(
        tester.widget<AnimatedOpacity>(lineChild(AnimatedOpacity)).opacity,
        0.8,
      );
      expect(
        tester.widget<AnimatedScale>(lineChild(AnimatedScale)).scale,
        0.98,
      );

      await pumpLine(tester, distance: 4);
      expect(
        tester.widget<AnimatedOpacity>(lineChild(AnimatedOpacity)).opacity,
        0.46,
      );
    });

    testWidgets('el modo visualizer usa transiciones más lentas y cuerpo 25',
        (tester) async {
      await pumpLine(
        tester,
        lit: true,
        distance: 0,
        visualizer: true,
        level: LyricsSyncLevel.line,
      );
      final opacity = tester.widget<AnimatedOpacity>(
        lineChild(AnimatedOpacity),
      );
      expect(opacity.duration, const Duration(milliseconds: 420));
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(LyricsLine),
          matching: find.byType(Text),
        ),
      );
      expect(text.textSpan!.toPlainText(), 'hola mundo');
    });
  });

  group('karaoke por wipe', () {
    testWidgets('la línea encendida con sync word arma dos capas + máscara',
        (tester) async {
      await pumpLine(tester, lit: true, distance: 0);
      expect(find.byType(WordWipeText), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);

      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(LyricsLine),
              matching: find.byType(Text),
            ),
          )
          .toList();
      expect(texts, hasLength(2));
      // Capa base apagada, capa encendida en blanco puro.
      expect(texts[0].textSpan!.style!.color!.a, closeTo(0.55, 0.001));
      expect(texts[1].textSpan!.style!.color, Colors.white);
    });

    testWidgets('sin nivel word va a texto plano (un solo Text)', (
      tester,
    ) async {
      await pumpLine(tester, lit: true, distance: 0, level: LyricsSyncLevel.line);
      expect(find.byType(WordWipeText), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LyricsLine),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('palabras que no reproducen la línea: guarda anti-reflow', (
      tester,
    ) async {
      await pumpLine(tester, lit: true, distance: 0, brokenWords: true);
      expect(find.byType(WordWipeText), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LyricsLine),
          matching: find.byType(Text),
        ),
        findsOneWidget,
      );
    });

    testWidgets('la línea apagada no gasta medición ni máscara', (
      tester,
    ) async {
      await pumpLine(tester, lit: false, distance: 2);
      expect(find.byType(WordWipeText), findsNothing);
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('el tap sobre la línea salta a su inicio', (tester) async {
      var seeks = 0;
      await pumpLine(tester, lit: true, distance: 0, onTap: () => seeks++);
      await tester.tap(find.byType(LyricsLine));
      expect(seeks, 1);
    });
  });

  group('huecos instrumentales', () {
    const gap = LyricsGap(beforeIndex: 1, startMs: 10000, endMs: 20000);

    Future<void> pumpGap(WidgetTester tester, int positionMs) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: LyricsGapDots(gap: gap, positionMs: positionMs),
            ),
          ),
        ),
      );
    }

    testWidgets('fuera del hueco conserva la altura sin dibujar puntos', (
      tester,
    ) async {
      await pumpGap(tester, 5000);
      expect(gapChild(Opacity), findsNothing);
      expect(tester.getSize(find.byType(LyricsGapDots)).height, 40);

      await pumpGap(tester, 30000);
      expect(gapChild(Opacity), findsNothing);
    });

    testWidgets('al entrar sube la opacidad de 0 a 1 en 400 ms', (
      tester,
    ) async {
      await pumpGap(tester, 10000);
      expect(tester.widget<Opacity>(gapChild(Opacity)).opacity, 0.0);

      await pumpGap(tester, 10200);
      expect(
        tester.widget<Opacity>(gapChild(Opacity)).opacity,
        closeTo(0.5, 0.001),
      );

      await pumpGap(tester, 10400);
      expect(
        tester.widget<Opacity>(gapChild(Opacity)).opacity,
        closeTo(1.0, 0.001),
      );
    });

    testWidgets('los puntos se llenan de a uno durante el silencio', (
      tester,
    ) async {
      Future<List<Color>> dotColors(int positionMs) async {
        await pumpGap(tester, positionMs);
        final dots = tester
            .widgetList<DecoratedBox>(
              gapChild(DecoratedBox),
            )
            .toList();
        expect(dots, hasLength(3));
        return dots
            .map((dot) => (dot.decoration as BoxDecoration).color!)
            .toList();
      }

      // Al inicio sólo el primero; al tercio, dos; al segundo tercio, tres.
      var colors = await dotColors(10001);
      expect(colors[0].a, closeTo(1.0, 0.001));
      expect(colors[1].a, closeTo(0.30, 0.001));

      colors = await dotColors(14000);
      expect(colors[0].a, closeTo(1.0, 0.001));
      expect(colors[1].a, closeTo(1.0, 0.001));
      expect(colors[2].a, closeTo(0.30, 0.001));

      colors = await dotColors(17000);
      expect(colors[2].a, closeTo(1.0, 0.001));
    });

    testWidgets('al terminar se desvanece y hace pop', (tester) async {
      await pumpGap(tester, 19900);
      final fading = tester.widget<Opacity>(gapChild(Opacity));
      expect(fading.opacity, closeTo(0.4, 0.001));

      final lateDot = tester.widgetList<Transform>(gapChild(Transform)).first;
      await pumpGap(tester, 14000);
      final midDot = tester.widgetList<Transform>(gapChild(Transform)).first;
      expect(
        lateDot.transform.getMaxScaleOnAxis(),
        greaterThan(midDot.transform.getMaxScaleOnAxis()),
      );
    });
  });
}
