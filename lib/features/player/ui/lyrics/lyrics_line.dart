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
/// plena opacidad y las demás bajan de a pasos (opacidad 0.72 → 0.38,
/// escala 0.98, blur por distancia) sobre una base apagada (0.42) que deja
/// a lo encendido con contraste claro. El cuerpo de la caja NUNCA cambia,
/// así que no hay reflow ni saltos en el auto-scroll.
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
    // La línea que se apaga decae más lento que la que se enciende: el
    // relevo entre versos se lee como un pase de testigo, no como dos
    // cambios simultáneos compitiendo.
    final fadeOut = Duration(milliseconds: visualizer ? 570 : 450);
    final curve = visualizer ? Curves.easeOutCubic : Curves.easeInOutCubic;
    final align =
        visualizer && landscape ? TextAlign.center : TextAlign.left;
    final dimColor = AppColors.textPrimary.withValues(alpha: 0.42);

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
      duration: lit ? duration : fadeOut,
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

  /// Resplandor de la línea encendida (se conserva del modo anterior, con
  /// más cuerpo para marcar lo que está sonando).
  List<Shadow> _glow() {
    if (visualizer) {
      return [
        Shadow(
          blurRadius: 16,
          color: AppColors.textPrimary.withValues(alpha: 0.28),
        ),
        Shadow(blurRadius: 30, color: AppColors.accent.withValues(alpha: 0.34)),
      ];
    }
    return [
      Shadow(
        blurRadius: 14,
        color: AppColors.textPrimary.withValues(alpha: 0.24),
      ),
      Shadow(blurRadius: 26, color: AppColors.accent.withValues(alpha: 0.22)),
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
///
/// `positionMs` llega cada ~200 ms (el `positionStream` de just_audio) y
/// un borde que salta 5 veces por segundo se ve trabado: el widget
/// interpola entre ticks con un ticker a 60 fps (la posición avanza
/// linealmente entre actualizaciones, así que el cruce es exacto) y corta
/// sin animar en seeks o cambios de línea.
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

class _WordWipeTextState extends State<WordWipeText>
    with SingleTickerProviderStateMixin {
  String? _cacheKey;
  String _text = '';
  List<LyricsWipeRow> _rows = const [];
  List<_RowClipper> _clippers = const [];

  /// Posición mostrada: interpola entre el último tick y el nuevo.
  late final AnimationController _advance;
  late double _shownMs;
  double _fromMs = 0;
  double _toMs = 0;

  @override
  void initState() {
    super.initState();
    _shownMs = widget.positionMs.toDouble();
    _fromMs = _shownMs;
    _toMs = _shownMs;
    _advance = AnimationController(vsync: this)
      ..addListener(() {
        _shownMs = _fromMs + (_toMs - _fromMs) * _advance.value;
      });
  }

  @override
  void didUpdateWidget(covariant WordWipeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.positionMs == oldWidget.positionMs) return;
    final target = widget.positionMs;
    final snap = !identical(widget.line, oldWidget.line) ||
        target < oldWidget.positionMs ||
        target - _toMs > 1500 ||
        target <= _shownMs;
    if (snap) {
      // Seek, retroceso o cambio de línea: corta, no barre de un extremo
      // a otro.
      _advance.stop();
      _fromMs = target.toDouble();
      _toMs = target.toDouble();
      _shownMs = target.toDouble();
      return;
    }
    // Tick normal: de donde estamos al nuevo valor, a velocidad real.
    _fromMs = _shownMs;
    _toMs = target.toDouble();
    _advance.duration =
        Duration(milliseconds: (target - _shownMs).round().clamp(16, 1500));
    _advance.forward(from: 0);
  }

  @override
  void dispose() {
    _advance.dispose();
    super.dispose();
  }

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
    var start = 0;
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final end = start + word.text.length;
      final glyphBoxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (glyphBoxes.isEmpty) {
        boxes.add(LyricsWipeBox(
          word: i,
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
        ));
        continue;
      }
      // Una caja por fragmento: la palabra que cruza el wrap deja un
      // fragmento por fila con los límites de ESA fila (medir con
      // first.left..last.right hacía retroceder el borde y dejaba la fila
      // de arriba sin terminar de encenderse).
      for (final glyphBox in glyphBoxes) {
        boxes.add(LyricsWipeBox(
          word: i,
          left: glyphBox.left,
          right: glyphBox.right,
          top: glyphBox.top,
          bottom: glyphBox.bottom,
        ));
      }
      start = end;
    }
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
        // El ticker sólo repinta las capas de ESTA línea mientras interpola
        // entre ticks; el resto de la hoja se enteró antes (5 Hz).
        return SizedBox(
          width: maxWidth,
          child: AnimatedBuilder(
            animation: _advance,
            builder: (context, _) {
              final positionMs = _shownMs.round();
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
                final edge = lyricsWipeRowEdge(widget.line, row, positionMs);
                final lit = _litRow(row, edge, i, fontSize, align);
                if (lit != null) layers.add(lit);
                // La banda de acento sólo tiene sentido mientras barre la
                // fila.
                if (edge > row.left + 0.5 && edge < row.right - 0.5) {
                  layers.add(_accentBand(row, edge, i, fontSize, align));
                }
              }
              return Stack(children: layers);
            },
          ),
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
