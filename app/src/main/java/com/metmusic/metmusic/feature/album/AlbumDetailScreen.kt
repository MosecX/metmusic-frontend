package com.metmusic.metmusic.feature.album

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicArtwork
import com.metmusic.metmusic.core.ui.components.MetMusicDivider
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Detalle de álbum (6E-1): artwork, metadata, botón "Reproducir todo" y la
 * lista de tracks. Top-level sin shell (slide-up/down), con back propio.
 */
@Composable
fun AlbumDetailScreen(
    onBack: () -> Unit,
    onArtistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    viewModel: AlbumDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    AlbumDetailScreenContent(
        state = state,
        onBack = onBack,
        onArtistClick = onArtistClick,
        onPlayTracks = onPlayTracks,
        onRetry = viewModel::retry,
    )
}

/** Composición pura del detalle de álbum (sin ViewModel), para previews. */
@Composable
fun AlbumDetailScreenContent(
    state: AlbumDetailUiState,
    onBack: () -> Unit,
    onArtistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val error = state.error
    val album = state.album
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background)
            .safeDrawingPadding(),
    ) {
        DetailTopBar(onBack = onBack)
        when {
            state.isLoading -> MetMusicLoading()
            error != null -> MetMusicErrorState(message = error, onRetry = onRetry)
            album != null -> AlbumBody(
                album = album,
                onArtistClick = onArtistClick,
                onPlayTracks = onPlayTracks,
            )
            else -> MetMusicEmptyState(
                title = "Álbum no disponible",
                subtitle = "No pudimos cargar este álbum. Probá de nuevo más tarde.",
            )
        }
    }
}

/** Top bar mínima con back (el título grande vive en el body). */
@Composable
private fun DetailTopBar(onBack: () -> Unit) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.pagePadding, vertical = spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Volver",
            )
        }
        Spacer(modifier = Modifier.weight(1f))
    }
}

/** Cuerpo del álbum: artwork, título, artista, metadata y tracks. */
@Composable
private fun AlbumBody(
    album: Album,
    onArtistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    val radius = LocalMetMusicRadius.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = spacing.xl),
            contentAlignment = Alignment.Center,
        ) {
            MetMusicArtwork(
                url = album.thumbnailUrl.ifEmpty { null },
                size = 220.dp,
                shape = RoundedCornerShape(radius.lg),
            )
        }
        Text(
            text = album.title,
            style = MetMusicTextStyles.headline,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
        )
        album.artist?.let { artistName ->
            val artistId = album.artistId
            if (artistId != null) {
                Text(
                    text = artistName,
                    style = MetMusicTextStyles.body,
                    color = MetMusicColors.accent,
                    modifier = Modifier
                        .padding(horizontal = spacing.pagePadding)
                        .padding(top = spacing.xs)
                        .clickable { onArtistClick(artistId) },
                )
            } else {
                Text(
                    text = artistName,
                    style = MetMusicTextStyles.body,
                    modifier = Modifier
                        .padding(horizontal = spacing.pagePadding)
                        .padding(top = spacing.xs),
                )
            }
        }
        Text(
            text = listOfNotNull(
                album.year.takeIf { it.isNotEmpty() },
                "${album.trackCount} canciones",
            ).joinToString(" · "),
            style = MetMusicTextStyles.caption,
            modifier = Modifier
                .padding(horizontal = spacing.pagePadding)
                .padding(top = spacing.xs),
        )
        if (album.tracks.isNotEmpty()) {
            Button(
                onClick = { onPlayTracks(album.tracks, 0) },
                modifier = Modifier
                    .padding(horizontal = spacing.pagePadding)
                    .padding(top = spacing.xl)
                    .fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MetMusicColors.accent,
                    contentColor = Color.Black,
                ),
                shape = RoundedCornerShape(radius.md),
            ) {
                Icon(
                    imageVector = Icons.Filled.PlayArrow,
                    contentDescription = null,
                    modifier = Modifier.size(20.dp),
                )
                Spacer(modifier = Modifier.width(spacing.sm))
                Text(
                    text = "Reproducir todo",
                    style = MetMusicTextStyles.button.copy(color = Color.Unspecified),
                )
            }
        }
        Spacer(modifier = Modifier.height(spacing.xl))
        MetMusicDivider()
        album.tracks.forEachIndexed { index, track ->
            MetMusicListItem(
                title = track.displayTitle,
                subtitle = track.artist,
                trailing = formatTrackDuration(track.durationSeconds),
                leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl }.ifEmpty { null },
                onClick = { onPlayTracks(album.tracks, index) },
            )
        }
        Spacer(modifier = Modifier.height(spacing.listBottomInset))
    }
}

/** "m:ss" para la duración; null cuando el track no la trae. */
private fun formatTrackDuration(seconds: Int): String? {
    if (seconds <= 0) return null
    return "%d:%02d".format(seconds / 60, seconds % 60)
}

@Preview(
    name = "AlbumDetail",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AlbumDetailScreenContentPreview() {
    MetMusicTheme {
        AlbumDetailScreenContent(
            state = AlbumDetailUiState.preview(),
            onBack = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "AlbumDetail loading",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AlbumDetailScreenContentPreviewLoading() {
    MetMusicTheme {
        AlbumDetailScreenContent(
            state = AlbumDetailUiState(),
            onBack = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "AlbumDetail error",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AlbumDetailScreenContentPreviewError() {
    MetMusicTheme {
        AlbumDetailScreenContent(
            state = AlbumDetailUiState.previewError(),
            onBack = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}
