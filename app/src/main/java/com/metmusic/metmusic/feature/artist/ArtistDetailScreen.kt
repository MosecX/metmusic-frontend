package com.metmusic.metmusic.feature.artist

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicAlbumCard
import com.metmusic.metmusic.core.ui.components.MetMusicArtwork
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Detalle de artista (6E-1): foto circular, bio, top tracks y discografía.
 * Top-level sin shell (slide-up/down), con back propio.
 */
@Composable
fun ArtistDetailScreen(
    onBack: () -> Unit,
    onAlbumClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    viewModel: ArtistDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    ArtistDetailScreenContent(
        state = state,
        onBack = onBack,
        onAlbumClick = onAlbumClick,
        onPlayTracks = onPlayTracks,
        onRetry = viewModel::retry,
    )
}

/** Composición pura del detalle de artista (sin ViewModel), para previews. */
@Composable
fun ArtistDetailScreenContent(
    state: ArtistDetailUiState,
    onBack: () -> Unit,
    onAlbumClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val error = state.error
    val artist = state.artist
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
            artist != null -> ArtistBody(
                artist = artist,
                onAlbumClick = onAlbumClick,
                onPlayTracks = onPlayTracks,
            )
            else -> MetMusicEmptyState(
                title = "Artista no disponible",
                subtitle = "No pudimos cargar este artista. Probá de nuevo más tarde.",
            )
        }
    }
}

/** Top bar mínima con back (el nombre vive en el body). */
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

/** Cuerpo del artista: foto, nombre, bio, top tracks y discografía. */
@Composable
private fun ArtistBody(
    artist: Artist,
    onAlbumClick: (String) -> Unit,
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
                url = artist.imageUrl.ifEmpty { null },
                size = 180.dp,
                shape = CircleShape,
            )
        }
        Text(
            text = artist.name,
            style = MetMusicTextStyles.headline,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = spacing.pagePadding),
        )
        artist.bio?.takeIf { it.isNotBlank() }?.let { bio ->
            Text(
                text = bio,
                style = MetMusicTextStyles.bodyLight,
                maxLines = 4,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier
                    .padding(horizontal = spacing.pagePadding)
                    .padding(top = spacing.sm),
            )
        }
        if (artist.topTracks.isNotEmpty()) {
            Button(
                onClick = { onPlayTracks(artist.topTracks, 0) },
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
                    text = "Reproducir top tracks",
                    style = MetMusicTextStyles.button.copy(color = Color.Unspecified),
                )
            }
            Spacer(modifier = Modifier.height(spacing.md))
            artist.topTracks.take(5).forEachIndexed { index, track ->
                MetMusicListItem(
                    title = track.displayTitle,
                    subtitle = track.artist,
                    trailing = formatTrackDuration(track.durationSeconds),
                    leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl }.ifEmpty { null },
                    onClick = { onPlayTracks(artist.topTracks, index) },
                )
            }
        }
        if (artist.albums.isNotEmpty()) {
            Spacer(modifier = Modifier.height(spacing.xl))
            MetMusicSectionHeader(title = "Discografía")
            LazyRow(
                contentPadding = PaddingValues(horizontal = spacing.pagePadding),
                horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
            ) {
                items(artist.albums, key = { it.albumId }) { album ->
                    MetMusicAlbumCard(
                        album = album,
                        onClick = { onAlbumClick(album.albumId) },
                    )
                }
            }
        }
        if (artist.topTracks.isEmpty() && artist.albums.isEmpty()) {
            Spacer(modifier = Modifier.height(spacing.xl))
            MetMusicEmptyState(
                title = "Sin contenido",
                subtitle = "Este artista no tiene canciones ni álbumes disponibles.",
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
    name = "ArtistDetail",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun ArtistDetailScreenContentPreview() {
    MetMusicTheme {
        ArtistDetailScreenContent(
            state = ArtistDetailUiState.preview(),
            onBack = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "ArtistDetail loading",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun ArtistDetailScreenContentPreviewLoading() {
    MetMusicTheme {
        ArtistDetailScreenContent(
            state = ArtistDetailUiState(),
            onBack = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "ArtistDetail error",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun ArtistDetailScreenContentPreviewError() {
    MetMusicTheme {
        ArtistDetailScreenContent(
            state = ArtistDetailUiState.previewError(),
            onBack = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
        )
    }
}
