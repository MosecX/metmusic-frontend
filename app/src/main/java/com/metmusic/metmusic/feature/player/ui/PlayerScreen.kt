package com.metmusic.metmusic.feature.player.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicArtwork
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.core.ui.util.glass
import com.metmusic.metmusic.feature.player.PlayerUiState
import com.metmusic.metmusic.feature.player.PlayerViewModel

/**
 * Player minimal (6A-2): cerrar, arte grande, título/artista/álbum,
 * play/pausa y favorito. Sin shell, por lo que aplica sus propios insets
 * (`safeDrawingPadding`). El FullPlayer completo (slider, shuffle, repeat,
 * cola, letras, share) llega en 6G.
 */
@Composable
fun PlayerScreen(
    onClose: () -> Unit,
    viewModel: PlayerViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val isFavorite by viewModel.isFavorite.collectAsStateWithLifecycle()
    PlayerScreenContent(
        state = state,
        isFavorite = isFavorite,
        onClose = onClose,
        onPlayPause = viewModel::togglePlayPause,
        onToggleFavorite = viewModel::toggleFavorite,
    )
}

/** Composición pura del player (sin ViewModel), lista para previews. */
@Composable
fun PlayerScreenContent(
    state: PlayerUiState,
    isFavorite: Boolean,
    onClose: () -> Unit,
    onPlayPause: () -> Unit,
    onToggleFavorite: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val radius = LocalMetMusicRadius.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background)
            .safeDrawingPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            IconButton(onClick = onClose) {
                Icon(
                    imageVector = Icons.Filled.KeyboardArrowDown,
                    contentDescription = "Cerrar",
                    tint = MetMusicColors.textPrimary,
                )
            }
        }
        Spacer(modifier = Modifier.weight(1f))
        Box(modifier = Modifier.glass(shape = RoundedCornerShape(radius.sheet))) {
            MetMusicArtwork(
                url = state.artworkUrl.takeIf { it.isNotEmpty() },
                size = 240.dp,
                shape = RoundedCornerShape(radius.card),
                modifier = Modifier.padding(spacing.sm),
            )
        }
        Spacer(modifier = Modifier.height(spacing.xl))
        Text(
            text = state.title,
            style = MetMusicTextStyles.sectionTitle,
            color = MetMusicColors.textPrimary,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
        )
        Spacer(modifier = Modifier.height(spacing.xs))
        Text(
            text = state.artist,
            style = MetMusicTextStyles.bodyLight,
            color = MetMusicColors.textSecondary,
            textAlign = TextAlign.Center,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
        )
        if (state.album.isNotEmpty()) {
            Spacer(modifier = Modifier.height(spacing.xs))
            Text(
                text = state.album,
                style = MetMusicTextStyles.caption,
                color = MetMusicColors.textTertiary,
                textAlign = TextAlign.Center,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.padding(horizontal = spacing.pagePadding),
            )
        }
        state.error?.let { error ->
            Spacer(modifier = Modifier.height(spacing.sm))
            Text(
                text = error,
                style = MetMusicTextStyles.caption,
                color = MetMusicColors.danger,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = spacing.pagePadding),
            )
        }
        Spacer(modifier = Modifier.height(spacing.xl))
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(spacing.lg),
        ) {
            IconButton(
                onClick = onPlayPause,
                modifier = Modifier.size(72.dp),
            ) {
                Icon(
                    imageVector = if (state.isPlaying) PlayerIcons.Pause else Icons.Filled.PlayArrow,
                    contentDescription = if (state.isPlaying) "Pausar" else "Reproducir",
                    tint = MetMusicColors.textPrimary,
                    modifier = Modifier.size(40.dp),
                )
            }
            IconButton(onClick = onToggleFavorite) {
                Icon(
                    imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                    contentDescription = if (isFavorite) {
                        "Quitar de favoritos"
                    } else {
                        "Agregar a favoritos"
                    },
                    tint = if (isFavorite) MetMusicColors.accent else MetMusicColors.textSecondary,
                )
            }
        }
        Spacer(modifier = Modifier.weight(1f))
    }
}

private fun playerScreenPreviewState(): PlayerUiState = PlayerUiState(
    track = Track(
        trackId = "preview-player-1",
        title = "Around the World",
        artist = "Daft Punk",
        album = "Homework",
        durationSeconds = 429,
    ),
    isPlaying = true,
)

@Preview(name = "PlayerScreen reproduciendo", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun PlayerScreenPlayingPreview() {
    MetMusicTheme {
        PlayerScreenContent(
            state = playerScreenPreviewState(),
            isFavorite = true,
            onClose = { /* no-op en preview */ },
            onPlayPause = { /* no-op en preview */ },
            onToggleFavorite = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "PlayerScreen con error", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun PlayerScreenErrorPreview() {
    MetMusicTheme {
        PlayerScreenContent(
            state = playerScreenPreviewState().copy(
                isPlaying = false,
                error = "No se pudo resolver el stream",
            ),
            isFavorite = false,
            onClose = { /* no-op en preview */ },
            onPlayPause = { /* no-op en preview */ },
            onToggleFavorite = { /* no-op en preview */ },
        )
    }
}
