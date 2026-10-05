import 'package:flutter/material.dart';

/// Paleta de color de MetMusic. Dark mode siempre, sin modo claro.
class AppColors {
  AppColors._();

  // --- Fondo ---
  /// Fondo base negro profundo.
  static const Color background = Color(0xFF0A0A0F);

  /// Variante ligeramente más clara para capas.
  static const Color backgroundAlt = Color(0xFF12121A);

  /// Gradiente de fondo global (tintes de color sobre negro).
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0A0F),
      Color(0xFF0D1014),
      Color(0xFF080A0E),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // --- Acentos ---
  /// Verde neón principal.
  static const Color accent = Color(0xFF1DB954);

  /// Tinte secundario para degradados.
  static const Color accentSecondary = Color(0xFF14B8A6);

  /// Degradado de acento por defecto.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentSecondary],
  );

  // --- Texto ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textTertiary = Color(0x80FFFFFF); // 50%
  static const Color textDisabled = Color(0x4DFFFFFF); // 30%

  // --- Glass ---
  /// Borde de vidrio (10% blanco).
  static const Color glassBorder = Color(0x1AFFFFFF);

  /// Relleno del estilo Glass 1 (15% blanco).
  static const Color glassFill = Color(0x26FFFFFF);

  /// Relleno del estilo Glass 2 (transparente).
  static const Color glassFillTransparent = Color(0x00FFFFFF);

  // --- Estados ---
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A524);
  static const Color success = Color(0xFF1DB954);
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
