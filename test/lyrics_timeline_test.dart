import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/lyrics.dart';
import 'package:metmusic/core/utils/lyrics_timeline.dart';

/// Contrato de la lógica de render de letras: escalera de distancia,
/// lookahead del scroll predictivo, huecos instrumentales y guardas del
/// karaoke por palabra. Todo es puro, sin widgets.
void main() {
  SyncedLine line(int timeMs, String text, {int? durationMs,
    List<SyncedWord> words = const []}) {
    return SyncedLine(
      timeMs: timeMs,
      text: text,
      durationMs: durationMs,
      words: words,
    );
  }

  group('escalera de distancia', () {
    test('opacidad am-lyrics 1 / .8 / .7 / .58 / .46', () {
      expect(lyricsOpacity(0), 1.0);
      expect(lyricsOpacity(1), 0.8);
      expect(lyricsOpacity(2), 0.7);
      expect(lyricsOpacity(3), 0.58);
      expect(lyricsOpacity(4), 0.46);
      expect(lyricsOpacity(99), 0.46);
      expect(lyricsOpacity(-1), 1.0);
    });

    test('escala sutil: 1.0 en la activa, 0.98 en el resto', () {
      expect(lyricsScale(0), 1.0);
      expect(lyricsScale(1), 0.98);
      expect(lyricsScale(4), 0.98);
    });

    test('distancia simétrica alrededor de la ancla', () {
      expect(lyricsDistance(2, 3, lit: false), 1);
      expect(lyricsDistance(4, 3, lit: false), 1);
      expect(lyricsDistance(3, 3, lit: true), 0);
      expect(lyricsDistance(5, 3, lit: false), 2);
      expect(lyricsDistance(0, 3, lit: false), 3);
    });

    test('en un hueco la ancla no está encendida: cae a distancia 1', () {
      expect(lyricsDistance(3, 3, lit: false), 1);
      expect(lyricsDistance(4, 3, lit: false), 1);
    });

    test('antes del primer verso no hay ancla', () {
      expect(lyricsDistance(0, -1, lit: false), 1);
      expect(lyricsDistance(2, -1, lit: false), 3);
    });
  });

  group('línea ancla', () {
    final lines = [line(1000, 'a'), line(5000, 'b'), line(9000, 'c')];

    test('-1 antes del primer verso', () {
      expect(lyricsAnchorIndex(lines, 0), -1);
      expect(lyricsAnchorIndex(lines, 999), -1);
    });

    test('avanza línea por línea y se queda en la última en los huecos', () {
      expect(lyricsAnchorIndex(lines, 1000), 0);
      expect(lyricsAnchorIndex(lines, 4999), 0);
      expect(lyricsAnchorIndex(lines, 5000), 1);
      // Silencio entre b y c (activeLineIndex daría -1 acá).
      expect(lyricsAnchorIndex(lines, 8999), 1);
      expect(lyricsAnchorIndex(lines, 90000), 2);
    });
  });

  group('scroll predictivo', () {
    test('acota el lookahead a 350..500 ms', () {
      final current = line(0, 'a', durationMs: 4000);
      expect(scrollLookaheadMs(current, line(4200, 'b'), 0), 350);
      expect(scrollLookaheadMs(current, line(4500, 'b'), 0), 500);
      expect(scrollLookaheadMs(current, line(4400, 'b'), 0), 400);
    });

    test('con hueco largo espera sólo 500 ms', () {
      final current = line(0, 'a', durationMs: 4000);
      expect(scrollLookaheadMs(current, line(30000, 'b'), 0), 500);
    });

    test('sin duration_ms mide desde la posición actual', () {
      final current = line(0, 'a');
      expect(scrollLookaheadMs(current, line(200, 'b'), 0), 350);
      expect(scrollLookaheadMs(current, line(600, 'b'), 0), 500);
    });
  });

  group('objetivo del scroll predictivo', () {
    final lines = [
      line(1000, 'a', durationMs: 4000),
      line(15000, 'b', durationMs: 4000),
      line(60000, 'c'),
    ];

    test('lista vacía o intro lejana no apunta nada', () {
      expect(predictiveScrollTarget(const [], -1, 0), isNull);
      expect(predictiveScrollTarget(lines, -1, 0), isNull);
      expect(predictiveScrollTarget(lines, -1, 400), isNull);
    });

    test('anticipa el primer verso 400 ms antes de que arranque', () {
      final target = predictiveScrollTarget(lines, -1, 600)!;
      expect(target.line, 0);
      expect(target.duration.inMilliseconds, 400);
    });

    test('con la próxima lejos apunta a la línea actual', () {
      final target = predictiveScrollTarget(lines, 0, 1000)!;
      expect(target.line, 0);
      expect(target.duration.inMilliseconds, 400);
    });

    test('cuando la próxima está a tiro apunta a ella', () {
      // Hueco de 10 s → lookahead 500 ms; quedan 400 ms hasta el verso.
      final target = predictiveScrollTarget(lines, 0, 14600)!;
      expect(target.line, 1);
      expect(target.duration.inMilliseconds, 400);
    });

    test('respeta el lookahead corto y nunca arranca en 0 ms', () {
      final short = [line(0, 'a', durationMs: 4000), line(4200, 'b')];
      final target = predictiveScrollTarget(short, 0, 3900)!;
      expect(target.line, 1);
      expect(target.duration.inMilliseconds, 300);

      final late = predictiveScrollTarget(lines, 0, 15500)!;
      expect(late.line, 1);
      expect(late.duration.inMilliseconds, 80);
    });

    test('en la última línea no hay a dónde ir', () {
      final last = [line(0, 'a', durationMs: 1000)];
      final target = predictiveScrollTarget(last, 0, 500)!;
      expect(target.line, 0);
      expect(target.duration.inMilliseconds, 400);
    });
  });

  group('progreso', () {
    test('recorre el tramo completo', () {
      expect(lyricsProgress(1000, 2000, 1000), 0.0);
      expect(lyricsProgress(1000, 2000, 1500), 0.5);
      expect(lyricsProgress(1000, 2000, 2000), 1.0);
      expect(lyricsProgress(1000, 2000, 9999), 1.0);
      expect(lyricsProgress(1000, 2000, 0), 0.0);
    });

    test('sin fin informado usa el fallback y evita la división por cero', () {
      expect(lyricsProgress(1000, null, 1000), 0.0);
      expect(lyricsProgress(1000, null, 1450), 0.5);
      expect(lyricsProgress(1000, null, 1000, fallbackMs: 0), 1.0);
    });
  });

  group('guarda de palabras', () {
    test('acepta cuando las palabras reproducen la línea', () {
      final ok = line(
        30370,
        'One more time',
        durationMs: 4130,
        words: const [
          SyncedWord(timeMs: 30370, durationMs: 1500, text: 'One more '),
          SyncedWord(timeMs: 31870, durationMs: 2630, text: 'time'),
        ],
      );
      expect(lyricsWordsMatchLine(ok), isTrue);
    });

    test('rechaza líneas sin palabras o con espacios rotos', () {
      expect(lyricsWordsMatchLine(line(0, 'hola')), isFalse);
      final broken = line(
        0,
        'hola mundo',
        words: const [
          SyncedWord(timeMs: 0, text: 'hola'),
          SyncedWord(timeMs: 500, text: 'mundo'),
        ],
      );
      expect(lyricsWordsMatchLine(broken), isFalse);
    });
  });

  group('borde del wipe', () {
    final painted = line(
      1000,
      'hola mundo',
      durationMs: 4000,
      words: const [
        SyncedWord(timeMs: 1000, durationMs: 2000, text: 'hola '),
        SyncedWord(timeMs: 3000, durationMs: 2000, text: 'mundo'),
      ],
    );
    const lefts = [0.0, 60.0];
    const rights = [55.0, 130.0];

    test('arranca en 0 y termina al final de la última palabra', () {
      expect(lyricsWipeEdge(painted, lefts, rights, 0), 0.0);
      expect(lyricsWipeEdge(painted, lefts, rights, 1000), 0.0);
      expect(lyricsWipeEdge(painted, lefts, rights, 5000), 130.0);
    });

    test('interpola dentro de la palabra que suena', () {
      expect(lyricsWipeEdge(painted, lefts, rights, 2000), 27.5);
      expect(lyricsWipeEdge(painted, lefts, rights, 4000), 95.0);
    });

    test('se queda en el último offset si las listas no calzan', () {
      expect(
        lyricsWipeEdge(painted, const [0.0], const [10.0], 5000),
        10.0,
      );
    });
  });

  group('huecos instrumentales', () {
    // intro 0..8000 (8 s) · verso 9000..20000 (11 s) · puente 24000..25000
    // (1 s, se descarta) · sin fin informado en `puente` → el tramo hacia
    // `final` no es medible · coda 41000..songEnd.
    final lines = [
      line(8000, 'intro', durationMs: 1000),
      line(20000, 'verso', durationMs: 4000),
      line(25000, 'puente'),
      line(40000, 'final', durationMs: 1000),
    ];

    test('intro ≥ 7 s antes de la primera línea', () {
      final gaps = instrumentalGaps(lines);
      expect(gaps, hasLength(2));
      expect(gaps.first.beforeIndex, 0);
      expect(gaps.first.startMs, 0);
      expect(gaps.first.endMs, 8000);
      expect(gaps.first.durationMs, 8000);
    });

    test('hueco intermedio entre fin de una línea y la siguiente', () {
      final gaps = instrumentalGaps(lines);
      final bridge = gaps[1];
      expect(bridge.beforeIndex, 1);
      expect(bridge.startMs, 9000);
      expect(bridge.endMs, 20000);
      expect(bridge.durationMs, 11000);
    });

    test('descarta silencios menores a 7 s', () {
      final short = [line(0, 'a', durationMs: 4000), line(9000, 'b')];
      expect(instrumentalGaps(short), isEmpty);
    });

    test('sin duration_ms en la línea anterior no hay hueco medible', () {
      final noDuration = [line(0, 'a'), line(30000, 'b')];
      expect(instrumentalGaps(noDuration), isEmpty);
    });

    test('coda final sólo si viene la duración de la canción', () {
      expect(instrumentalGaps(lines), hasLength(2));
      final withEnd = instrumentalGaps(lines, songEndMs: 60000);
      expect(withEnd.last.beforeIndex, 4);
      expect(withEnd.last.startMs, 41000);
      expect(withEnd.last.endMs, 60000);
      // Sin `duration_ms` en la última línea no hay coda medible.
      final open = [line(0, 'a')];
      expect(instrumentalGaps(open, songEndMs: 60000), isEmpty);
    });

    test('lista vacía no produce huecos', () {
      expect(instrumentalGaps(const []), isEmpty);
      expect(instrumentalGaps(const [], songEndMs: 60000), isEmpty);
    });
  });
}
