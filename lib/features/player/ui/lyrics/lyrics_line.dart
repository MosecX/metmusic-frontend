import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/models/lyrics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/lyrics_timeline.dart';

/// Distancia (en líneas) a la línea activa → sigma de desenfoque. La línea
/// activa sale nítida y los vecinos se desenfocan suave, para que las
/// líneas "emergen" de las borrosas al acercarse. Barato: tope en 8.
double _lineBlur(int distance, {double intensity = 1.0}) {
  if (distance <= 0) return 0;
  return (2.0 + (distance - 1) * 1.4).clamp(0.0, 8.0) * intensity;
}

/// Línea de letra de la hoja, en cualquiera de los dos modos.
///
/// Sigue la escalera de am-lyrics: la activa va a escala 1.0 / w700 / a
/// plena opacidad y las demás bajan de a pasos (opacidad 0.8 → 0.46, escala
/// 0.98, blur por distancia). El cuerpo de la caja NUNCA cambia, así que no
/// hay reflow ni saltos en el auto-scroll.
class LyricsLine extends StatelessWidget {
  const LyricsLine({
    super.key,
    required this.line,
    required this.lit,
    required this.distance,
    required this.level,
    required this.positionMs,
    required this.visualizer,
    required this.landscape,
    required this.onTap,
  });

  /// Línea sincronizada a renderizar.
  final SyncedLine line;

  /// `true` sólo mientras `activeLineIndex` dice que está sonando.
  final bool lit;

  /// Distancia a la línea de referencia (la del hueco en curso no cuenta
  /// como encendida).
  final int distance;

  /// Nivel de sincronía del track (puede variar por respuesta).
  final LyricsSyncLevel level;

  final int positionMs;
  final bool visualizer;
  final bool landscape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: visualizer ? 420 : 300);
    final curve = visualizer ? Curves.easeOutCubic : Curves.easeInOutCubic;
    final align =
        visualizer && landscape ? TextAlign.center : TextAlign.left;
    final dimColor = AppColors.textPrimary.withValues(alpha: 0.55);

    final style = TextStyle(
      color: lit ? AppColors.textPrimary : dimColor,
      fontSize: visualizer ? (landscape ? 30.0 : 25.0) : 22.0,
      fontWeight: lit
          ? FontWeight.w700
          : (visualizer ? FontWeight.w400 : FontWeight.w500),
      letterSpacing: visualizer && lit ? 0.4 : null,
      height: visualizer ? 1.36 : 1.34,
      shadows: lit ? _glow() : null,
    );

    Widget child = AnimatedDefaultTextStyle(
      duration: duration,
      curve: curve,
      style: style,
      child: _body(dimColor, align),
    );
    child = AnimatedScale(
      scale: lyricsScale(distance),
      duration: duration,
      curve: curve,
      alignment: align == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: child,
    );
    child = AnimatedOpacity(
      opacity: lyricsOpacity(distance),
      duration: duration,
      curve: curve,
      child: child,
    );

    final blur = _lineBlur(distance, intensity: visualizer ? 1.0 : 0.4);
    if (blur > 0.05) {
      child = ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      );
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        // Las capas del wipe están recortadas a su fila, así que sin un
        // hit-test opaco los toques en la parte vacía de la línea se caerían.
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: duration,
          curve: curve,
          margin: EdgeInsets.symmetric(vertical: visualizer ? (lit ? 9 : 6) : (lit ? 7 : 5)),
          padding: visualizer
              ? const EdgeInsets.symmetric(horizontal: 18, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: child,
        ),
      ),
    );
  }

  /// El karaoke por palabra sólo aplica a la línea encendida con
  /// `sync_level: word` y con palabras que reproducen el texto exacto
  /// (si no, reflowaría al activarse y caemos a texto plano).
  Widget _body(Color dimColor, TextAlign align) {
    if (lit && level == LyricsSyncLevel.word && lyricsWordsMatchLine(line)) {
      return WordWipeText(
        line: line,
        positionMs: positionMs,
        baseColor: dimColor,
        litColor: AppColors.textPrimary,
        textAlign: align,
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Text.rich(TextSpan(text: line.text), textAlign: align),
    );
  }

  /// Resplandor de la línea encendida (se conserva el del modo anterior).
  List<Shadow> _glow() {
    if (visualizer) {
      return [
        Shadow(
          blurRadius: 16,
          color: AppColors.textPrimary.withValues(alpha: 0.22),
        ),
        Shadow(blurRadius: 30, color: AppColors.accent.withValues(alpha: 0.28)),
      ];
    }
    return [
      Shadow(
        blurRadius: 14,
        color: AppColors.textPrimary.withValues(alpha: 0.18),
      ),
      Shadow(blurRadius: 26, color: AppColors.accent.withValues(alpha: 0.16)),
    ];
  }
}

/// Karaoke con wipe: capa base apagada + una capa encendida **por fila
/// visual** recortada a su rectángulo, más una banda de acento que barre el
/// borde.
///
/// El degradado de cada fila corre dentro del ancho de ESA fila, así una
/// línea que hace wrap se enciende fila por fila: lo ya cantado queda
/// encendido y la fila siguiente espera apagada (con un solo eje X para el
/// párrafo, todas las filas se encenderían juntas y al saltar de una a otra
/// se apagarían).
///
/// Los offsets de cada palabra se miden con `TextPainter` (con el mismo
/// ancho y escalado que usa el render) y se cachean por estilo: sólo se
/// re-mide cuando cambia la línea, no en cada tick de posición.
class WordWipeText extends StatefulWidget {
  const WordWipeText({
    super.key,
    required this.line,
    required this.positionMs,
    required this.baseColor,
    required this.litColor,
    required this.textAlign,
  });

  final SyncedLine line;
  final int positionMs;
  final Color baseColor;
  final Color litColor;
  final TextAlign textAlign;

  @override
  State<WordWipeText> createState() => _WordWipeTextState();
}

class _WordWipeTextState extends State<WordWipeText> {
  String? _cacheKey;
  String _text = '';
  List<double> _lefts = const [];
  List<double> _rights = const [];
  List<LyricsWipeRow> _rows = const [];
  List<_RowClipper> _clippers = const [];

  void _layout(
    BuildContext context,
    double maxWidth,
    TextStyle style,
  ) {
    final words = widget.line.words;
    _text = words.map((word) => word.text).join();
    final textScaler = MediaQuery.textScalerOf(context);
    final cacheKey = '$_text|${style.fontSize}|${style.fontWeight}|'
        '${style.letterSpacing}|${style.height}|${style.fontFamily}|'
        '$maxWidth|${widget.textAlign.name}|$textScaler';
    if (cacheKey == _cacheKey) return;

    final painter = TextPainter(
      text: TextSpan(text: _text, style: style),
      textDirection: Directionality.of(context),
      textAlign: widget.textAlign,
      textScaler: textScaler,
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);

    final boxes = <LyricsWipeBox>[];
    final lefts = <double>[];
    final rights = <double>[];
    var start = 0;
    for (final word in words) {
      final end = start + word.text.length;
      final glyphBoxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (glyphBoxes.isEmpty) {
        boxes.add(const LyricsWipeBox(left: 0, right: 0, top: 0, bottom: 0));
        lefts.add(0);
        rights.add(0);
      } else {
        final first = glyphBoxes.first;
        final last = glyphBoxes.last;
        boxes.add(LyricsWipeBox(
          left: first.left,
          right: last.right,
          top: first.top,
          bottom: first.bottom > last.bottom ? first.bottom : last.bottom,
        ));
        lefts.add(first.left);
        rights.add(last.right);
      }
      start = end;
    }
    _lefts = lefts;
    _rights = rights;
    _rows = lyricsWipeRows(boxes);
    _clippers = [for (final row in _rows) _RowClipper(row)];
    _cacheKey = cacheKey;
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style;
    final align = widget.textAlign;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawMax = constraints.maxWidth;
        final maxWidth = rawMax.isFinite ? rawMax : 1200.0;
        _layout(context, maxWidth, style);
        final fontSize = style.fontSize ?? 16;
        final layers = <Widget>[
          Text.rich(
            TextSpan(
              text: _text,
              style: TextStyle(color: widget.baseColor),
            ),
            textAlign: align,
          ),
        ];
        for (var i = 0; i < _rows.length; i++) {
          final row = _rows[i];
          final edge = lyricsWipeRowEdge(
            widget.line,
            _lefts,
            _rights,
            row,
            widget.positionMs,
          );
          final lit = _litRow(row, edge, i, fontSize, align);
          if (lit != null) layers.add(lit);
          // La banda de acento sólo tiene sentido mientras barre la fila.
          if (edge > row.left + 0.5 && edge < row.right - 0.5) {
            layers.add(_accentBand(row, edge, i, fontSize, align));
          }
        }
        return SizedBox(
          width: maxWidth,
          child: Stack(children: layers),
        );
      },
    );
  }

  /// Capa encendida de una fila, recortada a su caja y barrida con una
  /// rampa larga (1.6 em) para que el texto se prenda de a poco.
  /// `null` si la fila todavía no arrancó.
  Widget? _litRow(
    LyricsWipeRow row,
    double edge,
    int rowIndex,
    double fontSize,
    TextAlign align,
  ) {
    if (edge <= row.left + 0.5) return null;
    final clipper = _clippers[rowIndex];
    final lit = Text.rich(
      TextSpan(
        text: _text,
        style: TextStyle(color: widget.litColor),
      ),
      textAlign: align,
    );
    // Fila completa: el degradado sólo agregaría un caso degenerado.
    if (edge >= row.right - 0.5) {
      return Positioned.fill(
        child: ClipRect(clipper: clipper, child: lit),
      );
    }
    final feather = fontSize * 1.6;
    return Positioned.fill(
      child: ClipRect(
        clipper: clipper,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => _sweepShader(rect, edge, feather),
          child: lit,
        ),
      ),
    );
  }

  /// Rampa suave del barrido: alfa 1 hasta `edge - feather` y luego una
  /// caída en cuatro tramos (55 % / 85 % / 100 %) para evitar el corte
  /// "en seco" de un degradado lineal de dos paradas.
  Shader _sweepShader(Rect rect, double edge, double feather) {
    final width = rect.width <= 0 ? 1.0 : rect.width;
    final from = ((edge - feather) / width).clamp(0.0, 1.0);
    final to = (edge / width).clamp(0.0, 1.0);
    final span = to - from;
    return LinearGradient(
      colors: const [
        Colors.white,
        Colors.white,
        Colors.white,
        Colors.white,
        Colors.transparent,
      ],
      stops: [
        0.0,
        from,
        (from + span * 0.55).clamp(0.0, 1.0),
        (from + span * 0.85).clamp(0.0, 1.0),
        to,
      ],
    ).createShader(rect);
  }

  /// Banda de acento que barre el borde (luz que pasa sobre el texto): se
  /// pinta sólo dentro de la fila y desaparece a los lados.
  Widget _accentBand(
    LyricsWipeRow row,
    double edge,
    int rowIndex,
    double fontSize,
    TextAlign align,
  ) {
    return Positioned.fill(
      child: ClipRect(
        clipper: _clippers[rowIndex],
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            final width = rect.width <= 0 ? 1.0 : rect.width;
            final band = fontSize * 1.1;
            final before = ((edge - band) / width).clamp(0.0, 1.0);
            final peak = (edge / width).clamp(0.0, 1.0);
            final after = ((edge + band * 0.4) / width).clamp(0.0, 1.0);
            return LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: 0.85),
                Colors.transparent,
              ],
              stops: [before, max(before, min(after, peak)), after],
            ).createShader(rect);
          },
          child: Text.rich(
            TextSpan(
              text: _text,
              style: const TextStyle(
                color: AppColors.accent,
                shadows: <Shadow>[],
              ),
            ),
            textAlign: align,
          ),
        ),
      ),
    );
  }
}

/// Recorta a la caja de una fila visual: sin esto, el gradiente de una fila
/// se pintaría encima de las otras.
class _RowClipper extends CustomClipper<Rect> {
  const _RowClipper(this.row);

  final LyricsWipeRow row;

  Rect get _rect => Rect.fromLTRB(row.left, row.top, row.right, row.bottom);

  @override
  Rect getClip(Size size) => _rect.intersect(Offset.zero & size);

  @override
  bool shouldReclip(covariant _RowClipper oldClipper) =>
      oldClipper.row != row;
}
