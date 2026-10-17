package com.metmusic.metmusic.core.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

/**
 * Constantes glassmorphism, portadas desde GlassStyles (Flutter): Glass 1
 * (mini player) y Glass 2 (resto de la UI) comparten radio y blur.
 */
object MetMusicGlass {
    /** Radio por defecto de todas las capas de vidrio. */
    val cardRadius = 20.dp

    /** Radio del mini player / Glass 1. */
    val playerRadius = 20.dp

    /** Radio circular para miniaturas (thumbnails). */
    val thumbnailRadius = 12.dp

    /** Sigma del blur de fondo (boceto: 20–28). */
    val blurSigma = 20.dp
}

/** Esquema oscuro de MetMusic: siempre dark, sin modo claro. */
private val MetMusicDarkColorScheme = darkColorScheme(
    primary = MetMusicColors.accent,
    onPrimary = Color.Black,
    secondary = MetMusicColors.accentSecondary,
    onSecondary = Color.Black,
    tertiary = MetMusicColors.accentSecondary,
    onTertiary = Color.Black,
    background = MetMusicColors.background,
    onBackground = MetMusicColors.textPrimary,
    surface = MetMusicColors.background,
    onSurface = MetMusicColors.textPrimary,
    surfaceVariant = MetMusicColors.backgroundAlt,
    onSurfaceVariant = MetMusicColors.textSecondary,
    surfaceContainer = MetMusicColors.backgroundAlt,
    surfaceContainerHigh = MetMusicColors.backgroundAlt,
    surfaceContainerHighest = MetMusicColors.backgroundAlt,
    // Sin teñido por elevación: las capas del diseño son vidrio plano.
    surfaceTint = Color.Transparent,
    error = MetMusicColors.danger,
    onError = Color.White,
    outline = MetMusicColors.glassBorder,
    scrim = Color.Black,
)

/**
 * Tema raíz de MetMusic: esquema oscuro, tipografías Inter del diseño y
 * colores portados de Flutter.
 */
@Composable
fun MetMusicTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = MetMusicDarkColorScheme,
        typography = MetMusicTypography,
        content = content,
    )
}
