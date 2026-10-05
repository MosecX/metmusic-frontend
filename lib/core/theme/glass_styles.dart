import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Estilos glassmorphism de MetMusic.
///
/// - [GlassStyles.playerBorderRadius] + fill 15% blanco → Glass 1 (player).
/// - [GlassStyles.cardBorderRadius] + fill transparente → Glass 2 (resto UI).
///
/// Los widgets concretos viven en `lib/core/widgets/` ([GlassCard],
/// [GlassPlayerCard]) para mantener la separación de responsabilidades.
class GlassStyles {
  GlassStyles._();

  /// Radio por defecto de todas las capas de vidrio.
  static const double cardBorderRadius = 20;

  /// Radio del reproductor (Glass 1).
  static const double playerBorderRadius = 20;

  /// Desenfoque aplicado por BackdropFilter.
  static const double blurSigma = 6;

  // --- Glass 1: reproductor (relleno blanco 15%) ---
  static BoxDecoration playerDecoration({double borderRadius = playerBorderRadius}) {
    return BoxDecoration(
      color: AppColors.glassFill,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.0),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // --- Glass 2: resto de la UI (relleno transparente) ---
  static BoxDecoration cardDecoration({
    double borderRadius = cardBorderRadius,
    Color? fill,
  }) {
    return BoxDecoration(
      color: fill ?? AppColors.glassFillTransparent,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: AppColors.glassBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.0),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Filtro de blur reutilizable tanto por [GlassCard] como por [GlassPlayerCard].
  static final ImageFilter blurFilter = ImageFilter.blur(
    sigmaX: blurSigma,
    sigmaY: blurSigma,
  );

  /// Radio circular para miniaturas (thumbnails).
  static BorderRadius get thumbnailRadius => BorderRadius.circular(12);
}
