package com.metmusic.metmusic.core.ui.util

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.LocalMetMusicGlass
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius

/**
 * Capa de vidrio plana de MetMusic: recorta [shape], pinta [fill] y dibuja un
 * borde de 1 dp con [border]. Los valores por defecto salen de los tokens
 * ([LocalMetMusicGlass] y [LocalMetMusicRadius]).
 *
 * El blur real (RenderEffect) queda para 6G, cuando exista el FullPlayer.
 */
@Composable
fun Modifier.glass(
    shape: Shape = RoundedCornerShape(LocalMetMusicRadius.current.card),
    fill: Color = LocalMetMusicGlass.current.fill,
    border: Color = LocalMetMusicGlass.current.border,
): Modifier = this
    .clip(shape)
    .background(fill)
    .border(width = 1.dp, color = border, shape = shape)
