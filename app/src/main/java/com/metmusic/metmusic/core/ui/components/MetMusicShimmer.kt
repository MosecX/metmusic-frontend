package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Placeholder de carga de MetMusic (shimmer estático por ahora): bloque
 * `controlFill` recortado con [shape]. La animación del barrido llega como
 * upgrade en una fase posterior.
 */
@Composable
fun MetMusicShimmer(
    modifier: Modifier = Modifier,
    shape: Shape = RoundedCornerShape(LocalMetMusicRadius.current.md),
) {
    Box(
        modifier = modifier
            .clip(shape)
            .background(MetMusicColors.controlFill),
    )
}

@Preview(name = "MetMusicShimmer", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicShimmerPreview() {
    MetMusicTheme {
        MetMusicShimmer(
            modifier = Modifier
                .padding(LocalMetMusicSpacing.current.lg)
                .size(LocalMetMusicSpacing.current.huge),
        )
    }
}
