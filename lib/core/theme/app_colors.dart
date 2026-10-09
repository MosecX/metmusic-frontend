import 'package:flutter/material.dart';

/// Paleta de color de MetMusic. Dark mode siempre, sin modo claro.
class AppColors {
  AppColors._();

  // --- Fondo ---
  /// Fondo base negro puro (Apple Music dark).
  static const Color background = Color(0xFF000000);

  /// Variante elevada para capas (grupos de ajustes, `#1c1c1e`).
  static const Color backgroundAlt = Color(0xFF1C1C1E);

  /// Fondo global plano (el boceto usa negro puro, sin tintes).
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, background],
  );

  // --- Acentos ---
  /// Morado principal (Púrpura Apple, #BF5AF2).
  static const Color accent = Color(0xFFBF5AF2);

  /// Tinte secundario para degradados (violeta #7C4DFF).
  static const Color accentSecondary = Color(0xFF7C4DFF);

  /// Degradado de acento por defecto.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentSecondary],
  );

  // --- Texto ---
  /// Blanco puro (títulos).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secundario: `rgba(235, 235, 245, 0.6)` (label secundario iOS).
  static const Color textSecondary = Color(0x99EBEBF5);

  /// Terciario: `rgba(235, 235, 245, 0.3)` (label terciario iOS).
  static const Color textTertiary = Color(0x4DEBEBF5);

  /// Deshabilitado: 30% blanco.
  static const Color textDisabled = Color(0x4DFFFFFF);

  // --- Glass ---
  /// Borde de vidrio (`rgba(255, 255, 255, 0.14)`).
  static const Color glassBorder = Color(0x24FFFFFF);

  /// Relleno de vidrio (`rgba(255, 255, 255, 0.1)`).
  static const Color glassFill = Color(0x1AFFFFFF);

  /// Relleno del estilo Glass 2 (transparente).
  static const Color glassFillTransparent = Color(0x00FFFFFF);

  // --- Superficies ---
  /// Separadores (`rgba(255, 255, 255, 0.08)`).
  static const Color separator = Color(0x14FFFFFF);

  /// Relleno iOS de campos/segmentados (`rgba(118, 118, 128, 0.24)`).
  static const Color controlFill = Color(0x3D767680);

  // --- Estados ---
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A524);

  /// Verde de éxito (`#34c759`, systemGreen iOS).
  static const Color success = Color(0xFF34C759);

  static const Color info = Color(0xFF3B82F6);

  /// Genera un degradado oscuro derivado de un color dominante (artwork).
  static LinearGradient gradientFromColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final dark = hsl
        .withLightness((hsl.lightness * 0.25).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.9).clamp(0.0, 1.0))
        .toColor();
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.alphaBlend(dark.withValues(alpha: 0.65), background), background],
    );
  }
}
