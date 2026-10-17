package com.metmusic.metmusic.core.ui.design

import androidx.compose.animation.core.CubicBezierEasing
import androidx.compose.animation.core.Easing
import androidx.compose.runtime.staticCompositionLocalOf
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * Duraciones y curvas de las animaciones de MetMusic.
 *
 * Se provee por [LocalMetMusicMotion] desde [MetMusicTheme]; las
 * animaciones de las fases de UI leen de ahí.
 */
data class MetMusicMotion(
    val short: Duration = 150.milliseconds,
    val medium: Duration = 300.milliseconds,
    val long: Duration = 500.milliseconds,
    val standard: Easing = CubicBezierEasing(0.2f, 0f, 0f, 1f),
    val emphasized: Easing = CubicBezierEasing(0.3f, 0f, 0f, 1f),
)

val LocalMetMusicMotion = staticCompositionLocalOf { MetMusicMotion() }
