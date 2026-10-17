package com.metmusic.metmusic.core.ui.design

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Parámetros de las capas de vidrio de MetMusic (Glass 1 y Glass 2 del
 * diseño Flutter): relleno, borde, blur y alpha de contenido.
 *
 * Se provee por [LocalMetMusicGlass] desde [MetMusicTheme]; [Modifier.glass]
 * y las superficies futuras leen de ahí.
 */
data class MetMusicGlass(
    val fill: Color = Color(0x1AFFFFFF),
    val border: Color = Color(0x24FFFFFF),
    val blurSigma: Dp = 20.dp,
    val contentAlpha: Float = 1f,
)

val LocalMetMusicGlass = staticCompositionLocalOf { MetMusicGlass() }
