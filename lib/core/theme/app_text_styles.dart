import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografías de MetMusic (pesos 300 / 400 / 500 / 600 / 700).
class AppTextStyles {
  AppTextStyles._();

  /// Título grande de pantalla (`34 / 700 / -0.6`, estilo Apple large title).
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.1,
  );

  static const TextStyle display = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.1,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  /// Título de sección (`22 / 700 / -0.4`).
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Título de card (`15 / 600`), carruseles y tiles.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /// Subtítulo de card / meta (`13 / 400`, secundario).
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Título de fila (`16 / 500`).
  static const TextStyle rowTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Subtítulo de fila (`13.5 / 400`, secundario).
  static const TextStyle rowSubtitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Duración / valores tabulares (`13.5 / 400`, terciario).
  static const TextStyle rowTrailing = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
