import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/lyrics_timeline.dart';

/// Diámetro de cada punto: 0.4 em sobre el cuerpo de línea (am-lyrics).
const double _kDotSize = 9;

/// Altura fija de la fila: el espacio también comunica el instrumental.
const double _kRowHeight = 40;

/// Fila de hueco instrumental: tres puntos que se llenan de a uno,
/// respiran y hacen pop cuando termina el silencio (am-lyrics
/// `.lyrics-instrumental`).
///
/// Toda la animación es una función pura de `positionMs`, así que es
/// seek-safe y no corre ningún timer: si el usuario salta al medio del
/// hueco, los puntos salen exactamente donde deben. Fuera del hueco los
/// puntos quedan invisibles pero la fila conserva su altura.
class LyricsGapDots extends StatelessWidget {
  const LyricsGapDots({
    super.key,
    required this.gap,
    required this.positionMs,
  });

  final LyricsGap gap;
  final int positionMs;

  @override
  Widget build(BuildContext context) {
    final start = gap.startMs;
    final end = gap.endMs;
    if (positionMs < start || positionMs > end) {
      return const SizedBox(height: _kRowHeight);
    }

    final elapsed = positionMs - start;
    final remaining = end - positionMs;
    // Entrada (400 ms), respiración (ciclo de 4 s) y salida (pop en los
    // últimos 750 ms + desvanecido en los últimos 250 ms).
    final appear = (elapsed / 400).clamp(0.0, 1.0);
    final vanish = (remaining / 250).clamp(0.0, 1.0);
    final pop = (remaining / 750).clamp(0.0, 1.0);
    final breath = 0.85 + 0.275 * (0.5 + 0.5 * sin(2 * pi * elapsed / 4000));
    final scale = appear * breath * (1 + 0.2 * (1 - pop));
    final opacity = appear * vanish;
    final fillStep = gap.durationMs / 3;

    return SizedBox(
      height: _kRowHeight,
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              _dot(
                lit: elapsed >= fillStep * i,
                scale: scale,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot({required bool lit, required double scale}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: _kDotSize,
          height: _kDotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: lit
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.30),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
