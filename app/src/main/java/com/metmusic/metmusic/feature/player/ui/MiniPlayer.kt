package com.metmusic.metmusic.feature.player.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicArtwork
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.core.ui.util.glass
import com.metmusic.metmusic.feature.player.PlayerUiState

/**
 * MiniPlayer flotante del shell: arte, título/artista, play/pausa y
 * siguiente. Sin ViewModel: recibe estado y callbacks puros. Si no hay pista
 * cargada no renderiza nada.
 */
@Composable
fun MiniPlayer(
    state: PlayerUiState,
    onPlayPause: () -> Unit,
    onNext: () -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (!state.hasTrack) return
    val spacing = LocalMetMusicSpacing.current
    val radius = LocalMetMusicRadius.current
    val shape = RoundedCornerShape(radius.lg)
    Surface(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.md, vertical = spacing.xs)
            .height(64.dp)
            .glass(shape = shape),
        shape = shape,
        color = Color.Transparent,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = spacing.md),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(spacing.md),
        ) {
            MetMusicArtwork(
                url = state.artworkUrl.takeIf { it.isNotEmpty() },
                size = 40.dp,
                shape = RoundedCornerShape(radius.sm),
            )
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = state.title,
                    style = MetMusicTextStyles.rowTitle,
                    color = MetMusicColors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    text = state.artist,
                    style = MetMusicTextStyles.rowSubtitle,
                    color = MetMusicColors.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            IconButton(onClick = onPlayPause) {
                Icon(
                    imageVector = if (state.isPlaying) PlayerIcons.Pause else Icons.Filled.PlayArrow,
                    contentDescription = if (state.isPlaying) "Pausar" else "Reproducir",
                    tint = MetMusicColors.textPrimary,
                )
            }
            IconButton(onClick = onNext) {
                Icon(
                    imageVector = PlayerIcons.SkipNext,
                    contentDescription = "Siguiente",
                    tint = MetMusicColors.textPrimary,
                )
            }
        }
    }
}

private fun miniPlayerPreviewState(): PlayerUiState = PlayerUiState(
    track = Track(
        trackId = "preview-mini-1",
        title = "One More Time",
        artist = "Daft Punk",
        album = "Discovery",
        durationSeconds = 320,
    ),
    isPlaying = true,
)

@Preview(name = "MiniPlayer reproduciendo", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MiniPlayerPlayingPreview() {
    MetMusicTheme {
        MiniPlayer(
            state = miniPlayerPreviewState(),
            onPlayPause = { /* no-op en preview */ },
            onNext = { /* no-op en preview */ },
            onClick = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "MiniPlayer en pausa", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MiniPlayerPausedPreview() {
    MetMusicTheme {
        MiniPlayer(
            state = miniPlayerPreviewState().copy(isPlaying = false),
            onPlayPause = { /* no-op en preview */ },
            onNext = { /* no-op en preview */ },
            onClick = { /* no-op en preview */ },
        )
    }
}
