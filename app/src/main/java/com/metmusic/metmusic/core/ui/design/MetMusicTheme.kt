package com.metmusic.metmusic.core.ui.design

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.graphics.Color

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
 * Tema raíz de MetMusic: colores y tipografía por MaterialTheme (canon) y
 * tokens re-skinnables (spacing, radius, motion, glass) por CompositionLocals.
 *
 * Cambiar el look = pasar overrides, ej. `MetMusicTheme(radius = custom)`.
 */
@Composable
fun MetMusicTheme(
    spacing: MetMusicSpacing = MetMusicSpacing(),
    radius: MetMusicRadius = MetMusicRadius(),
    motion: MetMusicMotion = MetMusicMotion(),
    glass: MetMusicGlass = MetMusicGlass(),
    content: @Composable () -> Unit,
) {
    CompositionLocalProvider(
        LocalMetMusicSpacing provides spacing,
        LocalMetMusicRadius provides radius,
        LocalMetMusicMotion provides motion,
        LocalMetMusicGlass provides glass,
    ) {
        MaterialTheme(
            colorScheme = MetMusicDarkColorScheme,
            typography = MetMusicTypography,
            content = content,
        )
    }
}
