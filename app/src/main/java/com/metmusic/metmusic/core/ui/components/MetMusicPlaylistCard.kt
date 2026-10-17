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
import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/** Ancho fijo del card de playlist en carruseles horizontales. */
private val PlaylistCardWidth = 160.dp

/**
 * Card de playlist para carruseles de la Home: artwork cuadrado, título a
 * dos líneas y creador (o cantidad de canciones) a una línea.
 *
 * [onClick] es opcional: en 6B llega `null` porque el detalle de playlist
 * todavía no existe; las fases de detalles lo activan.
 */
@Composable
fun MetMusicPlaylistCard(
    playlist: Playlist,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val shape = RoundedCornerShape(LocalMetMusicRadius.current.md)
    Column(
        modifier = modifier
            .width(PlaylistCardWidth)
            .then(
                if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier,
            ),
    ) {
        MetMusicArtwork(
            url = playlist.thumbnailUrl.takeIf { it.isNotEmpty() },
            size = PlaylistCardWidth,
            shape = shape,
        )
        Spacer(modifier = Modifier.height(spacing.sm))
        BasicText(
            text = playlist.title,
            style = MetMusicTextStyles.cardTitle.copy(color = MetMusicColors.textPrimary),
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        val subtitle = playlist.creator?.takeIf { it.isNotBlank() }
            ?: "${playlist.trackCount} canciones"
        BasicText(
            text = subtitle,
            style = MetMusicTextStyles.cardSubtitle.copy(color = MetMusicColors.textSecondary),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

@Preview(name = "MetMusicPlaylistCard", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicPlaylistCardPreview() {
    MetMusicTheme {
        MetMusicPlaylistCard(
            playlist = Playlist(
                playlistId = "preview-playlist",
                title = "French Touch Classics",
                creator = "MetMusic",
                numberOfTracks = 42,
            ),
            onClick = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "MetMusicPlaylistCard sin creador", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicPlaylistCardNoCreatorPreview() {
    MetMusicTheme {
        MetMusicPlaylistCard(
            playlist = Playlist(
                playlistId = "preview-playlist-2",
                title = "Noche",
                numberOfTracks = 18,
            ),
            onClick = null,
        )
    }
}
