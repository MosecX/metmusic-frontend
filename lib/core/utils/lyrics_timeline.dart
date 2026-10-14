import 'dart:math';

import '../models/lyrics.dart';

/// Opacidad de una línea según su distancia a la línea activa. La
/// distinción entre lo ya cantado y lo que falta no se resuelve con el
/// color de la línea sino con el wipe por palabra, así que acá sólo manda
/// la distancia. Escalera más pronunciada que la de am-lyrics
/// (`1 / .72 / .58 / .47 / .38`) para que la línea encendida se separe
/// con claridad de las vecinas.
double lyricsOpacity(int distance) {
  if (distance <= 0) return 1;
  if (distance == 1) return 0.72;
  if (distance == 2) return 0.58;
  if (distance == 3) return 0.47;
  return 0.38;
}

/// Escala de una línea por distancia (am-lyrics: `scale(.98)` en las
/// inactivas). Es una escala puramente visual: la caja no cambia, así que
/// no hay reflow ni saltos en el auto-scroll.
double lyricsScale(int distance) => distance <= 0 ? 1.0 : 0.98;

/// Índice de la línea "ancla": la última cuyo `time_ms` ya pasó, o `-1`
/// antes del primer verso. Sirve de referencia cuando no hay línea
/// sonando, porque `Lyrics.activeLineIndex` devuelve `-1` en los huecos
/// instrumentales.
int lyricsAnchorIndex(List<SyncedLine> lines, int posMs) {
  var index = -1;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].timeMs > posMs) break;
    index = i;
  }
  return index;
}

/// Distancia de la línea [index] a la referencia [anchor] para la escalera
/// de estilos: simétrica (pasadas y futuras se alejan igual) y con la
/// línea ancla empujada a 1 cuando no está encendida (hueco en curso).
int lyricsDistance(int index, int anchor, {required bool lit}) {
  if (anchor < 0) return index + 1;
  final distance = (index - anchor).abs();
  if (distance == 0 && !lit) return 1;
  return distance;
}

/// Lookahead del scroll predictivo (am-lyrics): espera entre el fin de la
/// línea actual y el inicio de la siguiente, acotado a 350..500 ms. Si la
/// línea no trae `duration_ms`, se mide desde [positionMs] (el resto de la
/// canción, acotado igual).
int scrollLookaheadMs(SyncedLine current, SyncedLine next, int positionMs) {
  final end = current.endMs;
  final gap = end == null ? next.timeMs - positionMs : next.timeMs - end;
  if (gap < 350) return 350;
  if (gap > 500) return 500;
  return gap;
}

/// Línea a la que debe apuntar el scroll de la hoja y en cuánto tiempo.
///
/// Devuelve la próxima línea cuando ya está a tiro (la animación termina
/// justo cuando se enciende) y la actual mientras tanto; `null` si todavía
/// no hay nada que apuntar (intro lejana o lista vacía).
({int line, Duration duration})? predictiveScrollTarget(
  List<SyncedLine> lines,
  int anchorIndex,
  int positionMs,
) {
  if (lines.isEmpty) return null;
  const settled = Duration(milliseconds: 400);
  if (anchorIndex < 0) {
    final until = lines.first.timeMs - positionMs;
    if (until > 500) return null;
    return (line: 0, duration: Duration(milliseconds: until.clamp(80, 500)));
  }
  final upcoming = anchorIndex + 1;
  if (upcoming >= lines.length) {
    return (line: anchorIndex, duration: settled);
  }
  final lookahead =
      scrollLookaheadMs(lines[anchorIndex], lines[upcoming], positionMs);
  final until = lines[upcoming].timeMs - positionMs;
  if (until <= lookahead) {
    return (
      line: upcoming,
      duration: Duration(milliseconds: until.clamp(80, 500)),
    );
  }
  return (line: anchorIndex, duration: settled);
}

/// Progreso 0..1 de un tramo que va de [startMs] a [endMs] en [positionMs].
/// [fallbackMs] evita divisiones por cero cuando el fin no viene informado.
double lyricsProgress(int startMs, int? endMs, int positionMs,
    {int fallbackMs = 900}) {
  final end = endMs ?? startMs + fallbackMs;
  if (end <= startMs) return positionMs >= startMs ? 1 : 0;
  return ((positionMs - startMs) / (end - startMs)).clamp(0.0, 1.0);
}

/// `true` si las palabras concatenadas reproducen exactamente
/// `SyncedLine.text`. Si no se cumple, el render por palabras podría
/// reflow al activarse (falta/ sobra un espacio) y hay que caer a texto
/// plano.
bool lyricsWordsMatchLine(SyncedLine line) {
  if (line.words.isEmpty) return false;
  return line.words.map((w) => w.text).join() == line.text;
}

/// Un fragmento de una palabra en la caja medida por `TextPainter`: una
/// palabra que se parte en dos filas al hacer wrap produce dos fragmentos
/// (uno por fila), cada uno con sus propios límites en esa fila.
class LyricsWipeBox {
  const LyricsWipeBox({
    required this.word,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  /// Índice de la palabra a la que pertenece este fragmento.
  final int word;

  final double left;
  final double right;
  final double top;
  final double bottom;
}

/// Una fila visual del párrafo: los fragmentos de las palabras que comparten
/// línea al hacer wrap, con sus límites.
///
/// El wipe se resuelve fila por fila; si no, el único eje X del párrafo
/// encendería todas las filas a la vez y al saltar de una a otra apagaría
/// las anteriores.
class LyricsWipeRow {
  const LyricsWipeRow({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
    required this.fragments,
  });

  final double top;
  final double bottom;
  final double left;
  final double right;

  /// Fragmentos en orden de aparición (de palabra y, dentro de ella, de
  /// fila).
  final List<LyricsWipeBox> fragments;

  /// Índices de palabra de la fila, sin repetir y en orden.
  List<int> get words {
    final seen = <int>{};
    return [
      for (final box in fragments)
        if (seen.add(box.word)) box.word
    ];
  }
}

/// Agrupa los fragmentos [boxes] (uno por caja de `getBoxesForSelection`)
/// en filas visuales, por proximidad de `top` con tolerancia de 0.5 px para
/// absorber redondeos de subpixel. Devuelve las filas en orden de
/// aparición.
List<LyricsWipeRow> lyricsWipeRows(List<LyricsWipeBox> boxes) {
  final rows = <LyricsWipeRow>[];
  for (final box in boxes) {
    final rowIndex = rows.indexWhere((row) => (row.top - box.top).abs() <= 0.5);
    if (rowIndex < 0) {
      rows.add(LyricsWipeRow(
        top: box.top,
        bottom: box.bottom,
        left: box.left,
        right: box.right,
        fragments: [box],
      ));
      continue;
    }
    final row = rows[rowIndex];
    rows[rowIndex] = LyricsWipeRow(
      top: min(row.top, box.top),
      bottom: max(row.bottom, box.bottom),
      left: min(row.left, box.left),
      right: max(row.right, box.right),
      fragments: [...row.fragments, box],
    );
  }
  return rows;
}

/// Borde del wipe karaoke **dentro de** [row], en el mismo espacio de
/// coordenadas que el `TextPainter` (0,0 = origen del párrafo).
///
/// Recorre los fragmentos de la fila en orden: la fila terminada queda al
/// 100 % (`row.right`) y la que todavía no arrancó, apagada en `row.left`.
/// Los fragmentos de una palabra partida por el wrap se barren en paralelo
/// (cada uno dentro de su fila), así que el borde nunca retrocede y la
/// fila de arriba termina de encenderse al cantarse la palabra.
double lyricsWipeRowEdge(SyncedLine line, LyricsWipeRow row, int positionMs) {
  final fragments = row.fragments;
  var edge = row.left;
  var i = 0;
  while (i < fragments.length) {
    final wordIndex = fragments[i].word;
    // Span de la palabra en ESTA fila (un wrap puede partirlo en dos).
    var left = fragments[i].left;
    var right = fragments[i].right;
    var j = i + 1;
    while (j < fragments.length && fragments[j].word == wordIndex) {
      left = min(left, fragments[j].left);
      right = max(right, fragments[j].right);
      j++;
    }
    if (wordIndex >= line.words.length) break;
    final start = line.words[wordIndex].timeMs;
    final end = line.wordEndMs(wordIndex) ?? line.endMs ?? start + 900;
    if (positionMs >= end) {
      edge = right;
      i = j;
      continue;
    }
    if (positionMs <= start) {
      edge = left;
      break;
    }
    edge = left + (right - left) * lyricsProgress(start, end, positionMs);
    break;
  }
  if (edge < row.left) return row.left;
  if (edge > row.right) return row.right;
  return edge;
}

/// Hueco instrumental: un tramo sin letras de al menos 7 s (intro, puente
/// largo o coda) que se renderiza como tres puntos respirando.
class LyricsGap {
  const LyricsGap({
    required this.beforeIndex,
    required this.startMs,
    required this.endMs,
  });

  /// Índice de la línea que sigue al hueco (`lines.length` para el coda).
  final int beforeIndex;
  final int startMs;
  final int endMs;

  int get durationMs => endMs - startMs;
}

/// Huecos instrumentales de [lines] con al menos [minMs] de silencio.
/// El de la intro va antes de la línea 0; los intermedios necesitan que la
/// línea anterior traiga `duration_ms` (si no, "suena" hasta la siguiente
/// y no hay hueco medible). [songEndMs] habilita el coda final.
List<LyricsGap> instrumentalGaps(
  List<SyncedLine> lines, {
  int? songEndMs,
  int minMs = 7000,
}) {
  final gaps = <LyricsGap>[];
  for (var i = 0; i < lines.length; i++) {
    final start = i == 0 ? 0 : lines[i - 1].endMs;
    if (start == null) continue;
    final end = lines[i].timeMs;
    if (end - start >= minMs) {
      gaps.add(LyricsGap(beforeIndex: i, startMs: start, endMs: end));
    }
  }
  final lastEnd = lines.isEmpty ? null : lines.last.endMs;
  if (songEndMs != null && lastEnd != null && songEndMs - lastEnd >= minMs) {
    gaps.add(LyricsGap(
      beforeIndex: lines.length,
      startMs: lastEnd,
      endMs: songEndMs,
    ));
  }
  return gaps;
}
