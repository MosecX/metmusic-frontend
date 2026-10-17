package com.metmusic.metmusic.core.ui.design

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver

/**
 * Paleta de MetMusic, portada 1:1 desde AppColors (Flutter). Dark mode
 * siempre, sin modo claro.
 */
object MetMusicColors {
    // --- Fondo ---
    /** Fondo base negro puro (Apple Music dark). */
    val background = Color(0xFF000000)

    /** Variante elevada para capas (grupos de ajustes, #1C1C1E). */
    val backgroundAlt = Color(0xFF1C1C1E)

    // --- Acentos ---
    /** Morado principal (Púrpura Apple, #BF5AF2). */
    val accent = Color(0xFFBF5AF2)

    /** Tinte secundario para degradados (violeta #7C4DFF). */
    val accentSecondary = Color(0xFF7C4DFF)

    // --- Texto ---
    /** Blanco puro (títulos). */
    val textPrimary = Color(0xFFFFFFFF)

    /** Secundario: rgba(235, 235, 245, 0.6) (label secundario iOS). */
    val textSecondary = Color(0x99EBEBF5)

    /** Terciario: rgba(235, 235, 245, 0.3) (label terciario iOS). */
    val textTertiary = Color(0x4DEBEBF5)

    /** Deshabilitado: 30% blanco. */
    val textDisabled = Color(0x4DFFFFFF)

    // --- Glass ---
    /** Borde de vidrio: rgba(255, 255, 255, 0.14). */
    val glassBorder = Color(0x24FFFFFF)

    /** Relleno de vidrio: rgba(255, 255, 255, 0.1). */
    val glassFill = Color(0x1AFFFFFF)

    /** Relleno del estilo Glass 2 (transparente). */
    val glassFillTransparent = Color(0x00FFFFFF)

    // --- Superficies ---
    /** Separadores: rgba(255, 255, 255, 0.08). */
    val separator = Color(0x14FFFFFF)

    /** Relleno iOS de campos/segmentados: rgba(118, 118, 128, 0.24). */
    val controlFill = Color(0x3D767680)

    // --- Estados ---
    val danger = Color(0xFFE5484D)
    val warning = Color(0xFFF5A524)

    /** Verde de éxito (#34C759, systemGreen iOS). */
    val success = Color(0xFF34C759)
    val info = Color(0xFF3B82F6)

    /** Degradado de acento por defecto (izquierda → derecha). */
    val accentGradient: Brush = Brush.horizontalGradient(listOf(accent, accentSecondary))

    /**
     * Degradado oscuro derivado de un color dominante (artwork), port de
     * AppColors.gradientFromColor: el color se oscurece (luminosidad 25%,
     * saturación 90%) y se mezcla al 65% sobre el fondo negro, de arriba a
     * abajo.
     */
    fun artworkGradient(color: Color): Brush {
        val (hue, saturation, lightness) = color.toHsl()
        val dark = Color.hsl(
            hue = hue,
            saturation = (saturation * 0.9f).coerceIn(0f, 1f),
            lightness = (lightness * 0.25f).coerceIn(0f, 1f),
        )
        return Brush.verticalGradient(
            listOf(dark.copy(alpha = 0.65f).compositeOver(background), background),
        )
    }

    /** RGB → HSL: hue en grados (0..360), saturación y luminosidad (0..1). */
    private fun Color.toHsl(): Triple<Float, Float, Float> {
        val max = maxOf(red, green, blue)
        val min = minOf(red, green, blue)
        val delta = max - min
        val lightness = (max + min) / 2f
        if (delta == 0f) return Triple(0f, 0f, lightness)
        val saturation = if (lightness > 0.5f) delta / (2f - max - min) else delta / (max + min)
        val rawHue = when (max) {
            red -> 60f * (((green - blue) / delta) % 6f)
            green -> 60f * (((blue - red) / delta) + 2f)
            else -> 60f * (((red - green) / delta) + 4f)
        }
        return Triple((rawHue + 360f) % 360f, saturation, lightness)
    }
}
