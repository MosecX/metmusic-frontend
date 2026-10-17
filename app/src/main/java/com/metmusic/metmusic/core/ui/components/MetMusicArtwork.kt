package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.painter.ColorPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import coil3.compose.LocalPlatformContext
import coil3.request.ImageRequest
import coil3.request.crossfade
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Artwork cuadrado de MetMusic: imagen remota con Coil (crossfade) o bloque
 * `controlFill` con icono cuando no hay URL. El [shape] y el tamaño salen
 * del core de diseño.
 */
@Composable
fun MetMusicArtwork(
    url: String?,
    modifier: Modifier = Modifier,
    size: Dp? = null,
    shape: Shape = RoundedCornerShape(LocalMetMusicRadius.current.thumbnail),
    contentScale: ContentScale = ContentScale.Crop,
) {
    val base = if (size != null) modifier.size(size) else modifier
    val shaped = base.clip(shape)
    if (!url.isNullOrEmpty()) {
        AsyncImage(
            model = ImageRequest.Builder(LocalPlatformContext.current)
                .data(url)
                .crossfade(true)
                .build(),
            contentDescription = null,
            contentScale = contentScale,
            modifier = shaped,
            placeholder = ColorPainter(MetMusicColors.controlFill),
            error = ColorPainter(MetMusicColors.controlFill),
        )
    } else {
        Box(
            modifier = shaped.background(MetMusicColors.controlFill),
            contentAlignment = Alignment.Center,
        ) {
            Image(
                imageVector = Icons.Outlined.PlayArrow,
                contentDescription = null,
                colorFilter = ColorFilter.tint(MetMusicColors.textSecondary),
                modifier = Modifier.size(24.dp),
            )
        }
    }
}

@Preview(name = "MetMusicArtwork sin url", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicArtworkEmptyPreview() {
    MetMusicTheme {
        MetMusicArtwork(
            url = null,
            size = LocalMetMusicSpacing.current.huge,
            modifier = Modifier.padding(LocalMetMusicSpacing.current.lg),
        )
    }
}

@Preview(name = "MetMusicArtwork con url", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicArtworkWithUrlPreview() {
    MetMusicTheme {
        MetMusicArtwork(
            url = "https://example.com/artwork.jpg",
            size = LocalMetMusicSpacing.current.huge,
            modifier = Modifier.padding(LocalMetMusicSpacing.current.lg),
        )
    }
}

@Preview(name = "MetMusicArtwork grande", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicArtworkLargePreview() {
    MetMusicTheme {
        MetMusicArtwork(
            url = null,
            size = LocalMetMusicSpacing.current.huge * 2,
            modifier = Modifier.padding(LocalMetMusicSpacing.current.lg),
        )
    }
}
