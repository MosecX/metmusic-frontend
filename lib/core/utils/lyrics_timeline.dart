import 'dart:math';

import '../models/lyrics.dart';

/// Opacidad de una línea según su distancia a la línea activa
/// (am-lyrics: `1 / .8 / .7 / .58 / .46`). La distinción entre lo ya
/// cantado y lo que falta no se resuelve con el color de la línea sino con
/// el wipe por palabra, así que acá sólo manda la distancia.
double lyricsOpacity(int distance) {
  if (distance <= 0) return 1;
  if (distance == 1) return 0.8;
  if (distance == 2) return 0.7;
  if (distance == 3) return 0.58;
  return 0.46;
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

/// Posición en px del borde del wipe karaoke dentro de una línea.
///
/// [lefts] y [rights] son los offsets de cada palabra medidos con
/// `TextPainter`. El borde queda al final de la última palabra cantada, al
/// progreso de la que está sonando o al inicio de la primera que falta; si
/// no hay palabras que cantar todavía, en 0.
double lyricsWipeEdge(
  SyncedLine line,
  List<double> lefts,
  List<double> rights,
  int positionMs,
) {
  final words = line.words;
  final count = min(words.length, min(lefts.length, rights.length));
  var edge = 0.0;
  for (var i = 0; i < count; i++) {
    final start = words[i].timeMs;
    final end = line.wordEndMs(i) ?? line.endMs ?? start + 900;
    if (positionMs >= end) {
      edge = rights[i];
      continue;
    }
    if (positionMs <= start) {
      edge = lefts[i];
      break;
    }
    edge = lefts[i] +
        (rights[i] - lefts[i]) * lyricsProgress(start, end, positionMs);
    break;
  }
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
