package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/** Ancho fijo del card de artista en carruseles horizontales. */
private val ArtistCardWidth = 120.dp

/**
 * Card de artista para carruseles de la Home: foto circular y nombre
 * centrado a una línea.
 *
 * [onClick] es opcional: en 6B llega `null` porque el detalle de artista
 * todavía no existe; las fases de detalles lo activan.
 */
@Composable
fun MetMusicArtistCard(
    artist: Artist,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Column(
        modifier = modifier
            .width(ArtistCardWidth)
            .then(
                if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier,
            ),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        MetMusicArtwork(
            url = artist.imageUrl.takeIf { it.isNotEmpty() },
            size = ArtistCardWidth,
            shape = CircleShape,
        )
        Spacer(modifier = Modifier.height(spacing.sm))
        BasicText(
            text = artist.name,
            style = MetMusicTextStyles.cardTitle.copy(
                color = MetMusicColors.textPrimary,
                textAlign = TextAlign.Center,
            ),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Preview(name = "MetMusicArtistCard", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicArtistCardPreview() {
    MetMusicTheme {
        MetMusicArtistCard(
            artist = Artist(
                artistId = "preview-artist",
                name = "Daft Punk",
                picture = "https://example.com/artist.jpg",
            ),
            onClick = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "MetMusicArtistCard sin imagen", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicArtistCardNoImagePreview() {
    MetMusicTheme {
        MetMusicArtistCard(
            artist = Artist(artistId = "preview-artist-2", name = "Breakbot"),
            onClick = null,
        )
    }
}
