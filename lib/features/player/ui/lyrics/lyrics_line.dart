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

/// Karaoke con wipe: dos capas de texto superpuestas con el mismo layout,
/// la base apagada y la encendida recortada por un degradado que barre la
/// línea de izquierda a derecha con un borde suave de 0.75 em (am-lyrics
/// `--am-lyrics-progression-feather`).
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

  void _layout(
    BuildContext context,
    double maxWidth,
    TextStyle style,
  ) {
    final words = widget.line.words;
    _text = words.map((word) => word.text).join();
    final cacheKey = '$_text|${style.fontSize}|${style.fontWeight}|'
        '${style.letterSpacing}|${style.height}|${style.fontFamily}|'
        '$maxWidth|${widget.textAlign.name}';
    if (cacheKey == _cacheKey) return;

    final painter = TextPainter(
      text: TextSpan(text: _text, style: style),
      textDirection: Directionality.of(context),
      textAlign: widget.textAlign,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(minWidth: maxWidth, maxWidth: maxWidth);

    final lefts = <double>[];
    final rights = <double>[];
    var start = 0;
    for (final word in words) {
      final end = start + word.text.length;
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (boxes.isEmpty) {
        lefts.add(0);
        rights.add(0);
      } else {
        lefts.add(boxes.first.left);
        rights.add(boxes.last.right);
      }
      start = end;
    }
    _lefts = lefts;
    _rights = rights;
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
        final edge = lyricsWipeEdge(
          widget.line,
          _lefts,
          _rights,
          widget.positionMs,
        );
        final feather = (style.fontSize ?? 16) * 0.75;
        return SizedBox(
          width: maxWidth,
          child: Stack(
            children: [
              Text.rich(
                TextSpan(
                  text: _text,
                  style: TextStyle(color: widget.baseColor),
                ),
                textAlign: align,
              ),
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) {
                    final width = rect.width <= 0 ? 1.0 : rect.width;
                    final from = ((edge - feather) / width).clamp(0.0, 1.0);
                    final to = (edge / width).clamp(0.0, 1.0);
                    return LinearGradient(
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, from, to],
                    ).createShader(rect);
                  },
                  child: Text.rich(
                    TextSpan(
                      text: _text,
                      style: TextStyle(
                        color: widget.litColor,
                        shadows: const <Shadow>[],
                      ),
                    ),
                    textAlign: align,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
