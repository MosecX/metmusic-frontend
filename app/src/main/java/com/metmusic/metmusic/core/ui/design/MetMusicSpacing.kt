package com.metmusic.metmusic.core.ui.design

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Espaciados del diseño (paddings, gaps y alturas reservadas).
 *
 * Se provee por [LocalMetMusicSpacing] desde [MetMusicTheme]; los
 * componentes leen de ahí para que un re-skin no toque su código.
 */
data class MetMusicSpacing(
    val zero: Dp = 0.dp,
    val xs: Dp = 4.dp,
    val sm: Dp = 8.dp,
    val md: Dp = 12.dp,
    val lg: Dp = 16.dp,
    val xl: Dp = 24.dp,
    val xxl: Dp = 32.dp,
    val huge: Dp = 48.dp,
    val pagePadding: Dp = 16.dp,
    val sectionGap: Dp = 24.dp,
    val itemGap: Dp = 12.dp,
    val listBottomInset: Dp = 160.dp,
)

val LocalMetMusicSpacing = staticCompositionLocalOf { MetMusicSpacing() }
