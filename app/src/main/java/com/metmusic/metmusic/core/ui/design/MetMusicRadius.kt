package com.metmusic.metmusic.core.ui.design

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Radios del diseño (cards, miniaturas, chips, sheets).
 *
 * Se provee por [LocalMetMusicRadius] desde [MetMusicTheme]; los
 * componentes leen de ahí y convierten a shape con [asShape].
 */
data class MetMusicRadius(
    val sm: Dp = 8.dp,
    val md: Dp = 12.dp,
    val lg: Dp = 16.dp,
    val xl: Dp = 20.dp,
    val pill: Dp = 999.dp,
    val card: Dp = 20.dp,
    val thumbnail: Dp = 12.dp,
    val sheet: Dp = 24.dp,
    val chip: Dp = 999.dp,
) {
    /** Convierte un radio del set al shape redondeado equivalente. */
    fun asShape(radius: Dp): RoundedCornerShape = RoundedCornerShape(radius)
}

val LocalMetMusicRadius = staticCompositionLocalOf { MetMusicRadius() }
