package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/** Ancho fijo del card de álbum en carruseles horizontales. */
private val AlbumCardWidth = 140.dp

/**
 * Card de álbum para carruseles de la Home: artwork cuadrado, título a dos
 * líneas y artista opcional a una línea.
 *
 * [onClick] es opcional: en 6B llega `null` porque el detalle de álbum
 * todavía no existe; las fases de detalles lo activan.
 */
@Composable
fun MetMusicAlbumCard(
    album: Album,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val shape = RoundedCornerShape(LocalMetMusicRadius.current.md)
    Column(
        modifier = modifier
            .width(AlbumCardWidth)
            .then(
                if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier,
            ),
    ) {
        MetMusicArtwork(
            url = album.thumbnailUrl.takeIf { it.isNotEmpty() },
            size = AlbumCardWidth,
            shape = shape,
        )
        Spacer(modifier = Modifier.height(spacing.sm))
        BasicText(
            text = album.title,
            style = MetMusicTextStyles.cardTitle.copy(color = MetMusicColors.textPrimary),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        album.artist?.let { artist ->
            BasicText(
                text = artist,
                style = MetMusicTextStyles.cardSubtitle.copy(color = MetMusicColors.textSecondary),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Preview(name = "MetMusicAlbumCard", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicAlbumCardPreview() {
    MetMusicTheme {
        MetMusicAlbumCard(
            album = Album(
                albumId = "preview-album",
                title = "Random Access Memories",
                artist = "Daft Punk",
            ),
            onClick = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "MetMusicAlbumCard sin artista", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicAlbumCardNoArtistPreview() {
    MetMusicTheme {
        MetMusicAlbumCard(
            album = Album(albumId = "preview-album-2", title = "Homework"),
            onClick = null,
        )
    }
}
