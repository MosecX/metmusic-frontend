package com.metmusic.metmusic.feature.player.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.vector.path
import androidx.compose.ui.unit.dp

/**
 * Iconos del player que no viven en `material-icons-core` (Pause y SkipNext
 * solo existen en `material-icons-extended`, que no es dependencia del
 * proyecto).
 *
 * Se dibujan con [ImageVector.Builder] usando los paths estándar de
 * Material; el color final lo aplica el `tint` de `Icon()`.
 */
internal object PlayerIcons {

    /** Pausa de Material: dos barras verticales. */
    val Pause: ImageVector = ImageVector.Builder(
        name = "MetMusicPause",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f,
    ).apply {
        path(fill = SolidColor(Color.Black)) {
            moveTo(6f, 5f)
            lineTo(10f, 5f)
            lineTo(10f, 19f)
            lineTo(6f, 19f)
            close()
            moveTo(14f, 5f)
            lineTo(18f, 5f)
            lineTo(18f, 19f)
            lineTo(14f, 19f)
            close()
        }
    }.build()

    /** Siguiente de Material: triángulo + barra. */
    val SkipNext: ImageVector = ImageVector.Builder(
        name = "MetMusicSkipNext",
        defaultWidth = 24.dp,
        defaultHeight = 24.dp,
        viewportWidth = 24f,
        viewportHeight = 24f,
    ).apply {
        path(fill = SolidColor(Color.Black)) {
            moveTo(6f, 18f)
            lineTo(14.5f, 12f)
            lineTo(6f, 6f)
            close()
            moveTo(16f, 6f)
            lineTo(18f, 6f)
            lineTo(18f, 18f)
            lineTo(16f, 18f)
            close()
        }
    }.build()
}
