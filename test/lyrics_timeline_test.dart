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
    test('opacidad 1 / .72 / .58 / .47 / .38 con contraste marcado', () {
      expect(lyricsOpacity(0), 1.0);
      expect(lyricsOpacity(1), 0.72);
      expect(lyricsOpacity(2), 0.58);
      expect(lyricsOpacity(3), 0.47);
      expect(lyricsOpacity(4), 0.38);
      expect(lyricsOpacity(99), 0.38);
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

  group('borde del wipe por fila', () {
    final painted = line(
      1000,
      'hola mundo',
      durationMs: 4000,
      words: const [
        SyncedWord(timeMs: 1000, durationMs: 2000, text: 'hola '),
        SyncedWord(timeMs: 3000, durationMs: 2000, text: 'mundo'),
      ],
    );

    // Las dos palabras miden en la misma fila (sin wrap).
    final single = lyricsWipeRows(const [
      LyricsWipeBox(word: 0, left: 0, right: 55, top: 10, bottom: 34),
      LyricsWipeBox(word: 1, left: 60, right: 130, top: 10, bottom: 34),
    ]);

    // Misma línea partida en dos filas: palabra 0 arriba, palabra 1 abajo.
    final wrapped = lyricsWipeRows(const [
      LyricsWipeBox(word: 0, left: 0, right: 180, top: 10, bottom: 34),
      LyricsWipeBox(word: 1, left: 8, right: 70, top: 46, bottom: 70),
    ]);

    // Palabra 0 partida por el wrap: un fragmento en cada fila (la caja
    // de `getBoxesForSelection` trae una por línea visual).
    final split = lyricsWipeRows(const [
      LyricsWipeBox(word: 0, left: 100, right: 180, top: 10, bottom: 34),
      LyricsWipeBox(word: 0, left: 0, right: 60, top: 46, bottom: 70),
      LyricsWipeBox(word: 1, left: 70, right: 130, top: 46, bottom: 70),
    ]);

    test('agrupa las cajas por fila visual', () {
      expect(single, hasLength(1));
      expect(single.first.words, [0, 1]);
      expect(single.first.left, 0);
      expect(single.first.right, 130);

      expect(wrapped, hasLength(2));
      expect(wrapped[0].words, [0]);
      expect(wrapped[1].words, [1]);
      expect(wrapped[1].left, 8);
      expect(wrapped[1].right, 70);

      // La palabra partida aporta un fragmento a cada fila.
      expect(split, hasLength(2));
      expect(split[0].words, [0]);
      expect(split[1].words, [0, 1]);
      expect(split[1].right, 130);
    });

    test('una sola fila: arranca en 0 y termina al final de la última', () {
      final row = single.first;
      expect(lyricsWipeRowEdge(painted, row, 0), 0.0);
      expect(lyricsWipeRowEdge(painted, row, 1000), 0.0);
      expect(lyricsWipeRowEdge(painted, row, 5000), 130.0);
    });

    test('interpola dentro de la palabra que suena', () {
      final row = single.first;
      expect(lyricsWipeRowEdge(painted, row, 2000), 27.5);
      expect(lyricsWipeRowEdge(painted, row, 4000), 95.0);
    });

    test('con wrap, la fila siguiente espera apagada', () {
      // En pleno canto de la palabra 0: la de arriba barriendo y la de
      // abajo intacta (con el eje X global del párrafo se encendía sola).
      expect(lyricsWipeRowEdge(painted, wrapped[0], 2000), 90.0);
      expect(lyricsWipeRowEdge(painted, wrapped[1], 2000), 8.0);
    });

    test('la fila terminada queda encendida al pasar a la siguiente', () {
      // Justo en el corte (3000): la de arriba al 100 %, la de abajo sin
      // arrancar (con el eje global, la de arriba se apagaba acá).
      expect(lyricsWipeRowEdge(painted, wrapped[0], 3000), 180.0);
      expect(lyricsWipeRowEdge(painted, wrapped[1], 3000), 8.0);
      // Cantando en la fila de abajo: la de arriba sigue intacta.
      expect(lyricsWipeRowEdge(painted, wrapped[0], 4000), 180.0);
      expect(lyricsWipeRowEdge(painted, wrapped[1], 4000), 39.0);
    });

    test('al terminar queda al 100 % dentro de los límites de la fila', () {
      expect(lyricsWipeRowEdge(painted, wrapped[1], 5000), 70.0);
      expect(lyricsWipeRowEdge(painted, wrapped[0], 9999), 180.0);
    });

    test('palabra partida por el wrap barre ambas filas sin retroceder', () {
      // Canto de la palabra 0 (1000..3000): la fila de arriba avanza de
      // 100 a 180 (antes retrocedía a la caja de la otra fila) y la de
      // abajo enciende su propio fragmento de la misma palabra.
      expect(lyricsWipeRowEdge(painted, split[0], 2000), 140.0);
      expect(lyricsWipeRowEdge(painted, split[1], 2000), 30.0);

      // Al terminar la palabra: la fila de arriba completa y la de abajo
      // con su fragmento al 100 % (queda lista para la siguiente).
      expect(lyricsWipeRowEdge(painted, split[0], 3000), 180.0);
      expect(lyricsWipeRowEdge(painted, split[1], 3000), 70.0);

      // Cantando la palabra 1 sólo en la fila de abajo.
      expect(lyricsWipeRowEdge(painted, split[0], 4000), 180.0);
      expect(lyricsWipeRowEdge(painted, split[1], 4000), 100.0);
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
