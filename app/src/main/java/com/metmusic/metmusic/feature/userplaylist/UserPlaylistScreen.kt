package com.metmusic.metmusic.feature.userplaylist

import androidx.compose.foundation.background
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist
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
import com.metmusic.metmusic.feature.userplaylist.addtracks.AddTracksScreen
import com.metmusic.metmusic.feature.userplaylist.components.DraggableTrackList

/**
 * Detalle editable de una playlist propia (6E-2): top-level fuera del shell
 * (slide-up/down), con back propio, "Reproducir todo", toggle de edición y la
 * lista de canciones.
 *
 * En modo edición la lista permite reordenar con drag & drop y quitar
 * canciones con el trash; el FAB "Agregar tracks" abre [AddTracksScreen] como
 * [androidx.compose.ui.window.Dialog] full-screen embebido (no es una ruta).
 */
@Composable
fun UserPlaylistScreen(
    onBack: () -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    viewModel: UserPlaylistViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showAddTracks by rememberSaveable { mutableStateOf(false) }

    UserPlaylistScreenContent(
        state = state,
        onBack = onBack,
        onPlayTracks = onPlayTracks,
        onAddTracksClick = { showAddTracks = true },
        onToggleEditMode = viewModel::toggleEditMode,
        onRemoveTrack = viewModel::removeTrack,
        onMoveTrack = viewModel::moveTrack,
        onRetry = viewModel::retry,
        onDismissActionError = viewModel::dismissActionError,
    )

    if (showAddTracks) {
        AddTracksScreen(
            onDismiss = { showAddTracks = false },
            onConfirm = { trackIds ->
                showAddTracks = false
                viewModel.addTracks(trackIds)
            },
        )
    }
}

/** Composición pura de la playlist propia (sin ViewModel), para previews. */
@Composable
fun UserPlaylistScreenContent(
    state: UserPlaylistUiState,
    onBack: () -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    onAddTracksClick: () -> Unit,
    onToggleEditMode: () -> Unit,
    onRemoveTrack: (String) -> Unit,
    onMoveTrack: (Int, Int) -> Unit,
    onRetry: () -> Unit,
    onDismissActionError: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val snackbarHostState = remember { SnackbarHostState() }
    val error = state.error
    val playlist = state.playlist

    LaunchedEffect(state.actionError) {
        val message = state.actionError
        if (message != null) {
            snackbarHostState.showSnackbar(message)
            onDismissActionError()
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background)
            .safeDrawingPadding(),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            UserPlaylistTopBar(
                isEditMode = state.isEditMode,
                onBack = onBack,
                onToggleEditMode = onToggleEditMode,
            )
            when {
                state.isLoading && playlist == null -> MetMusicLoading()
                error != null -> MetMusicErrorState(message = error, onRetry = onRetry)
                playlist != null -> UserPlaylistBody(
                    playlist = playlist,
                    tracks = state.tracks,
                    isEditMode = state.isEditMode,
                    isSavingOrder = state.isSavingOrder,
                    onPlayTracks = onPlayTracks,
                    onRemoveTrack = onRemoveTrack,
                    onMoveTrack = onMoveTrack,
                )
                else -> MetMusicEmptyState(
                    title = "Playlist no disponible",
                    subtitle = "No pudimos cargar esta playlist. Probá de nuevo más tarde.",
                )
            }
        }
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
        if (state.isEditMode && playlist != null) {
            ExtendedFloatingActionButton(
                text = {
                    Text(
                        text = "Agregar tracks",
                        style = MetMusicTextStyles.button.copy(color = Color.Unspecified),
                    )
                },
                icon = {
                    Icon(
                        imageVector = Icons.Filled.Add,
                        contentDescription = null,
                    )
                },
                onClick = onAddTracksClick,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = spacing.pagePadding, bottom = spacing.md),
                containerColor = MetMusicColors.accent,
                contentColor = Color.Black,
            )
        }
    }
}

/** Top bar mínima: back + toggle de edición (el título vive en el body). */
@Composable
private fun UserPlaylistTopBar(
    isEditMode: Boolean,
    onBack: () -> Unit,
    onToggleEditMode: () -> Unit,
) {
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
        IconButton(onClick = onToggleEditMode) {
            Icon(
                imageVector = if (isEditMode) Icons.Filled.Check else Icons.Filled.Edit,
                contentDescription = if (isEditMode) "Listo" else "Editar",
            )
        }
    }
}

/** Cuerpo: header compacto, "Reproducir todo" y la lista según el modo. */
@Composable
private fun UserPlaylistBody(
    playlist: UserPlaylist,
    tracks: List<Track>,
    isEditMode: Boolean,
    isSavingOrder: Boolean,
    onPlayTracks: (List<Track>, Int) -> Unit,
    onRemoveTrack: (String) -> Unit,
    onMoveTrack: (Int, Int) -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    val radius = LocalMetMusicRadius.current
    Column(modifier = Modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            MetMusicArtwork(
                url = playlist.thumbnailUrl.ifEmpty { null },
                size = 100.dp,
                shape = RoundedCornerShape(radius.lg),
            )
            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(start = spacing.md),
            ) {
                Text(
                    text = playlist.name,
                    style = MetMusicTextStyles.headline,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                playlist.description?.takeIf { it.isNotBlank() }?.let { description ->
                    Text(
                        text = description,
                        style = MetMusicTextStyles.bodyLight,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                Text(
                    text = "${tracks.size} canciones",
                    style = MetMusicTextStyles.caption,
                )
            }
        }
        Button(
            onClick = { onPlayTracks(tracks, 0) },
            enabled = tracks.isNotEmpty(),
            modifier = Modifier
                .padding(horizontal = spacing.pagePadding)
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
        if (isEditMode && isSavingOrder) {
            Text(
                text = "Guardando orden…",
                style = MetMusicTextStyles.caption,
                modifier = Modifier.padding(
                    start = spacing.pagePadding,
                    end = spacing.pagePadding,
                    top = spacing.xs,
                ),
            )
        }
        Spacer(modifier = Modifier.height(spacing.md))
        MetMusicDivider()
        when {
            tracks.isEmpty() -> Box(modifier = Modifier.weight(1f)) {
                MetMusicEmptyState(
                    title = "Playlist vacía",
                    subtitle = if (isEditMode) {
                        "Agregá tu primera canción."
                    } else {
                        "Activá Editar para agregar canciones."
                    },
                    icon = Icons.AutoMirrored.Outlined.List,
                )
            }
            isEditMode -> DraggableTrackList(
                tracks = tracks,
                onMove = onMoveTrack,
                onRemove = onRemoveTrack,
                modifier = Modifier.weight(1f),
            )
            else -> LazyColumn(modifier = Modifier.weight(1f)) {
                itemsIndexed(tracks, key = { _, track -> track.trackId }) { index, track ->
                    MetMusicListItem(
                        title = track.displayTitle,
                        subtitle = track.artist,
                        trailing = formatTrackDuration(track.durationSeconds),
                        leadingUrl = track.listThumbnailUrl
                            .ifEmpty { track.thumbnailUrl }
                            .ifEmpty { null },
                        onClick = { onPlayTracks(tracks, index) },
                    )
                }
                item {
                    Spacer(modifier = Modifier.height(spacing.listBottomInset))
                }
            }
        }
    }
}

/** "m:ss" para la duración; null cuando el track no la trae. */
private fun formatTrackDuration(seconds: Int): String? {
    if (seconds <= 0) return null
    return "%d:%02d".format(seconds / 60, seconds % 60)
}

/** Wrapper de previews: tema + contenido con callbacks no-op. */
@Composable
private fun UserPlaylistPreview(state: UserPlaylistUiState) {
    MetMusicTheme {
        UserPlaylistScreenContent(
            state = state,
            onBack = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
            onAddTracksClick = { /* no-op en preview */ },
            onToggleEditMode = { /* no-op en preview */ },
            onRemoveTrack = { /* no-op en preview */ },
            onMoveTrack = { _, _ -> /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onDismissActionError = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "UserPlaylist · lectura",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun UserPlaylistScreenPreview() {
    UserPlaylistPreview(UserPlaylistUiState.preview())
}

@Preview(
    name = "UserPlaylist · edición",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun UserPlaylistScreenEditPreview() {
    UserPlaylistPreview(UserPlaylistUiState.previewEdit())
}

@Preview(
    name = "UserPlaylist · vacía",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun UserPlaylistScreenEmptyPreview() {
    UserPlaylistPreview(UserPlaylistUiState.previewEmpty())
}

@Preview(
    name = "UserPlaylist · error",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun UserPlaylistScreenErrorPreview() {
    UserPlaylistPreview(UserPlaylistUiState.previewError())
}
