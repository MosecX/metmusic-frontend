package com.metmusic.metmusic.feature.mix

import android.graphics.Color
import android.view.ViewGroup
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color as CoreColor
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.ui.components.MetMusicArtwork
import com.metmusic.metmusic.core.ui.components.MetMusicDivider
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles

/**
 * Pantalla de estación radial (FASE 6F).
 *
 * - Ruta fuera del shell: [com.metmusic.metmusic.navigation.Routes.Mix].
 * - Back propio, sin bottom bar, sin MiniPlayer.
 * - Transición slide-up/down 300 ms (misma constante que Album/Artist/Playlist).
 * - `Reproducir estación` encola toda la estación desde el track 0.
 * - Corazón en el top bar: guarda/elimina el mix localmente.
 * - Estado de error (red) con "Reintentar"; estado 404 con "Volver".
 */
@Composable
fun MixScreen(
    onBack: () -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    viewModel: MixViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.actionError) {
        state.actionError?.let { message ->
            snackbarHostState.showSnackbar(message)
            viewModel.dismissActionError()
        }
    }

    MixScreenContent(
        state = state,
        snackbarHostState = snackbarHostState,
        onBack = onBack,
        onPlayTracks = onPlayTracks,
        onToggleFavorite = viewModel::toggleFavorite,
        onRetry = viewModel::retry,
    )
}

@Composable
fun MixScreenContent(
    state: MixUiState,
    snackbarHostState: SnackbarHostState,
    onBack: () -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    onToggleFavorite: () -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current

    Box(
        modifier = modifier.fillMaxSize().background(MetMusicColors.background),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .safeDrawingPadding(),
        ) {
            // ---- Top bar: back + corazón (solo con estación cargada) ----
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(
                        horizontal = spacing.pagePadding,
                        vertical = spacing.sm,
                    ),
                horizontalArrangement = Arrangement.spacedBy(spacing.md),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(
                    onClick = onBack,
                    modifier = Modifier.minimumTouchTargetSize(
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ),
                ) {
                    Icon(
                        imageVector = Icons.Filled.ArrowBack,
                        contentDescription = "Volver",
                    )
                }
                Spacer(modifier = Modifier.weight(1f))
                if (state.station != null) {
                    IconButton(
                        onClick = onToggleFavorite,
                        enabled = !state.isTogglingFavorite,
                        modifier = Modifier.minimumTouchTargetSize(
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                        ),
                    ) {
                        Icon(
                            imageVector = if (state.isFavorite) {
                                Icons.Filled.Favorite
                            } else {
                                Icons.Filled.FavoriteBorder
                            },
                            contentDescription = if (state.isFavorite) {
                                "Quitar de favoritos"
                            } else {
                                "Guardar en favoritos"
                            },
                            tint = if (state.isFavorite) {
                                MetMusicColors.accent
                            } else {
                                MetMusicColors.textPrimary
                            },
                        )
                    }
                }
            }

            when {
                state.isLoading -> {
                    MetMusicLoading(
                        modifier = Modifier.fillMaxSize(),
                    )
                }

                state.error != null -> {
                    MetMusicErrorState(
                        message = state.error,
                        onRetry = onRetry,
                    )
                }

                state.isNotFound -> {
                    MetMusicEmptyState(
                        title = "Esta pista no tiene estación",
                        subtitle = "No hay una estación de radio para esta canción.",
                        icon = Icons.Outlined.Info,
                        actionLabel = "Volver",
                        onAction = onBack,
                    )
                }

                state.station != null -> {
                    MixBody(
                        state = state,
                        onPlayTracks = onPlayTracks,
                    )
                }

                else -> {
                    MetMusicEmptyState(
                        title = "Estación no disponible",
                        subtitle = null,
                        icon = Icons.Outlined.Info,
                        actionLabel = "Reintentar",
                        onAction = onRetry,
                    )
                }
            }
        }

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}

@Composable
private fun MixBody(
    state: MixUiState,
    onPlayTracks: (List<Track>, Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current

    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            top = spacing.xl,
            bottom = spacing.listBottomInset,
        ),
    ) {
        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = spacing.pagePadding),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                MetMusicArtwork(
                    url = state.imageUrl,
                    size = 100.dp,
                    shape = com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius.current.lg,
                )
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(start = spacing.md),
                    verticalArrangement = Arrangement.Center,
                ) {
                    Text(
                        text = state.title,
                        style = MetMusicTextStyles.headline,
                        maxLines = 2,
                    )
                    state.subTitle?.let { sub ->
                        Text(
                            text = sub,
                            style = MetMusicTextStyles.body,
                            color = MetMusicColors.textSecondary,
                        )
                    }
                    Text(
                        text = "${state.tracks.size} canciones",
                        style = MetMusicTextStyles.caption,
                    )
                }
            }
        }

        state.description?.let { desc ->
            item {
                Text(
                    text = desc,
                    style = MetMusicTextStyles.bodyLight,
                    modifier = Modifier.padding(
                        horizontal = spacing.pagePadding,
                        vertical = spacing.sm,
                    ),
                    maxLines = 3,
                    overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis,
                )
            }
        }

        item {
            Button(
                onClick = { onPlayTracks(state.tracks, 0) },
                enabled = state.tracks.isNotEmpty(),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = spacing.pagePadding, vertical = spacing.xl),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MetMusicColors.accent,
                    contentColor = CoreColor.Black,
                ),
                shape = com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius.current.md,
            ) {
                Icon(
                    imageVector = Icons.Filled.PlayArrow,
                    contentDescription = "Reproducir estación",
                    modifier = Modifier.size(20.dp),
                )
                androidx.compose.foundation.layout.Spacer(
                    modifier = Modifier.width(spacing.sm),
                )
                Text(
                    text = "Reproducir estación",
                    style = MetMusicTextStyles.button,
                )
            }
        }

        item {
            Spacer(
                modifier = Modifier.height(spacing.lg),
            )
        }

        item {
            MetMusicDivider()
        }

        itemsIndexed(
            items = state.tracks,
            key = { _, track -> track.trackId },
        ) { index, track ->
            MetMusicListItem(
                title = track.displayTitle,
                subtitle = track.artist,
                trailing = formatDuration(track.durationSeconds),
                leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl },
                onClick = { onPlayTracks(state.tracks, index) },
            )
        }
    }
}

/** "mm:ss"; null cuando los segundos no valen para una duración. */
private fun formatDuration(seconds: Int): String? {
    if (seconds <= 0) return null
    return "%d:%02d".format(seconds / 60, seconds % 60)
}

// ---------- Preview ----------
@Preview(
    name = "MixScreenContent",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun MixScreenContentPreview() {
    MetMusicTheme {
        MixScreenContent(
            state = MixUiState.preview(),
            snackbarHostState = remember { SnackbarHostState() },
            onBack = {},
            onPlayTracks = { _, _ -> /* preview */ },
            onToggleFavorite = {},
            onRetry = {},
        )
    }
}

@Preview(
    name = "MixScreenContent · not found",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun MixScreenContentPreviewNotFound() {
    MetMusicTheme {
        MixScreenContent(
            state = MixUiState.previewNotFound(),
            snackbarHostState = remember { SnackbarHostState() },
            onBack = {},
            onPlayTracks = { _, _ -> /* preview */ },
            onToggleFavorite = {},
            onRetry = {},
        )
    }
}

@Preview(
    name = "MixScreenContent · error",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun MixScreenContentPreviewError() {
    MetMusicTheme {
        MixScreenContent(
            state = MixUiState.previewError(),
            snackbarHostState = remember { SnackbarHostState() },
            onBack = {},
            onPlayTracks = { _, _ -> /* preview */ },
            onToggleFavorite = {},
            onRetry = {},
        )
    }
}

@Preview(
    name = "MixScreenContent · loading",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun MixScreenContentPreviewLoading() {
    MetMusicTheme {
        MixScreenContent(
            state = MixUiState.previewLoading(),
            snackbarHostState = remember { SnackbarHostState() },
            onBack = {},
            onPlayTracks = { _, _ -> /* preview */ },
            onToggleFavorite = {},
            onRetry = {},
        )
    }
}
