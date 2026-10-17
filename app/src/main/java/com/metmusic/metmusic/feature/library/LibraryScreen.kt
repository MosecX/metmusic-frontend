package com.metmusic.metmusic.feature.library

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.outlined.DateRange
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FloatingActionButton
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
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.HistoryEntry
import com.metmusic.metmusic.core.model.SavedMix
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist
import com.metmusic.metmusic.core.ui.components.MetMusicChip
import com.metmusic.metmusic.core.ui.components.MetMusicDivider
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.feature.library.components.ClearHistoryDialog
import com.metmusic.metmusic.feature.library.components.CreatePlaylistDialog
import com.metmusic.metmusic.feature.library.components.DeletePlaylistDialog
import com.metmusic.metmusic.feature.library.components.RenamePlaylistDialog
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Biblioteca real (6C): cuatro tabs con gestión local completa sobre
 * playlists propias, favoritos, mixes guardados e historial. Los detalles
 * (PlaylistDetail, MixScreen) y la reproducción llegan en 6E/6F/6G, así que
 * las filas no navegan todavía.
 */
@Composable
fun LibraryScreen(
    onGoToSearch: () -> Unit,
    modifier: Modifier = Modifier,
    viewModel: LibraryViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    var showCreateDialog by remember { mutableStateOf(false) }
    var renameTarget by remember { mutableStateOf<UserPlaylist?>(null) }
    var deleteTarget by remember { mutableStateOf<UserPlaylist?>(null) }
    var showClearHistoryDialog by remember { mutableStateOf(false) }
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(state.actionError) {
        val message = state.actionError
        if (message != null) {
            snackbarHostState.showSnackbar(message)
            viewModel.dismissActionError()
        }
    }

    LibraryScreenContent(
        state = state,
        snackbarHostState = snackbarHostState,
        onTabSelected = viewModel::selectTab,
        onRefresh = viewModel::refresh,
        onRetry = viewModel::retry,
        onGoToSearch = onGoToSearch,
        onCreateClick = { showCreateDialog = true },
        onRenameClick = { renameTarget = it },
        onDeleteClick = { deleteTarget = it },
        onRemoveFavorite = viewModel::removeFavorite,
        onRemoveMix = viewModel::removeMix,
        onClearHistoryClick = { showClearHistoryDialog = true },
        modifier = modifier,
    )

    if (showCreateDialog) {
        CreatePlaylistDialog(
            onCreate = { name, description, coverUrl ->
                viewModel.createPlaylist(name, description, coverUrl)
                showCreateDialog = false
            },
            onDismiss = { showCreateDialog = false },
        )
    }
    renameTarget?.let { target ->
        RenamePlaylistDialog(
            initialName = target.name,
            onRename = { newName ->
                viewModel.renamePlaylist(target.playlistId, newName)
                renameTarget = null
            },
            onDismiss = { renameTarget = null },
        )
    }
    deleteTarget?.let { target ->
        DeletePlaylistDialog(
            playlistName = target.name,
            onConfirm = {
                viewModel.deletePlaylist(target.playlistId)
                deleteTarget = null
            },
            onDismiss = { deleteTarget = null },
        )
    }
    if (showClearHistoryDialog) {
        ClearHistoryDialog(
            onConfirm = {
                viewModel.clearHistory()
                showClearHistoryDialog = false
            },
            onDismiss = { showClearHistoryDialog = false },
        )
    }
}

/** Composición pura de la Biblioteca (sin ViewModel); los dialogs viven en [LibraryScreen]. */
@Composable
fun LibraryScreenContent(
    state: LibraryUiState,
    snackbarHostState: SnackbarHostState,
    onTabSelected: (LibraryTab) -> Unit,
    onRefresh: () -> Unit,
    onRetry: () -> Unit,
    onGoToSearch: () -> Unit,
    onCreateClick: () -> Unit,
    onRenameClick: (UserPlaylist) -> Unit,
    onDeleteClick: (UserPlaylist) -> Unit,
    onRemoveFavorite: (String) -> Unit,
    onRemoveMix: (String) -> Unit,
    onClearHistoryClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val error = state.error
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            Text(
                text = "Biblioteca",
                style = MetMusicTextStyles.largeTitle,
                modifier = Modifier.padding(
                    start = spacing.pagePadding,
                    end = spacing.pagePadding,
                    top = spacing.md,
                    bottom = spacing.sm,
                ),
            )
            LibraryTabChips(
                selectedTab = state.selectedTab,
                onTabSelected = onTabSelected,
            )
            MetMusicDivider()
            Box(modifier = Modifier.weight(1f)) {
                when {
                    state.isLoading -> MetMusicLoading()
                    error != null -> MetMusicErrorState(
                        message = error,
                        onRetry = onRetry,
                    )
                    else -> when (state.selectedTab) {
                        LibraryTab.PLAYLISTS -> PlaylistsContent(
                            playlists = state.playlists,
                            onRenameClick = onRenameClick,
                            onDeleteClick = onDeleteClick,
                            onGoToSearch = onGoToSearch,
                        )
                        LibraryTab.FAVORITES -> FavoritesContent(
                            favorites = state.favorites,
                            onRemoveFavorite = onRemoveFavorite,
                            onGoToSearch = onGoToSearch,
                        )
                        LibraryTab.MIXES -> MixesContent(
                            mixes = state.mixes,
                            onRemoveMix = onRemoveMix,
                            onGoToSearch = onGoToSearch,
                        )
                        LibraryTab.HISTORY -> HistoryContent(
                            history = state.history,
                            onClearHistoryClick = onClearHistoryClick,
                            onGoToSearch = onGoToSearch,
                        )
                    }
                }
            }
        }
        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
        if (state.selectedTab == LibraryTab.PLAYLISTS) {
            FloatingActionButton(
                onClick = onCreateClick,
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(end = spacing.pagePadding, bottom = spacing.md),
                containerColor = MetMusicColors.accent,
                contentColor = Color.Black,
            ) {
                Icon(
                    imageVector = Icons.Filled.Add,
                    contentDescription = "Crear playlist",
                )
            }
        }
    }
}

/** Fila de chips con las cuatro pestañas de la Biblioteca. */
@Composable
private fun LibraryTabChips(
    selectedTab: LibraryTab,
    onTabSelected: (LibraryTab) -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
        horizontalArrangement = Arrangement.spacedBy(spacing.sm),
    ) {
        LibraryTab.entries.forEach { tab ->
            MetMusicChip(
                label = tab.label,
                selected = selectedTab == tab,
                onClick = { onTabSelected(tab) },
            )
        }
    }
}

@Composable
private fun PlaylistsContent(
    playlists: List<UserPlaylist>,
    onRenameClick: (UserPlaylist) -> Unit,
    onDeleteClick: (UserPlaylist) -> Unit,
    onGoToSearch: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    if (playlists.isEmpty()) {
        MetMusicEmptyState(
            title = "No tenés playlists",
            subtitle = "Creá tu primera playlist con el botón +.",
            icon = Icons.AutoMirrored.Outlined.List,
            actionLabel = "Buscar música",
            onAction = onGoToSearch,
        )
    } else {
        LazyColumn(
            contentPadding = PaddingValues(
                top = spacing.sm,
                bottom = spacing.listBottomInset,
            ),
        ) {
            items(playlists, key = { playlist -> playlist.playlistId }) { playlist ->
                MetMusicListItem(
                    title = playlist.name,
                    subtitle = "${playlist.trackCount} canciones",
                    leadingUrl = playlist.coverUrl,
                    trailingContent = {
                        IconButton(onClick = { onRenameClick(playlist) }) {
                            Icon(
                                imageVector = Icons.Filled.Edit,
                                contentDescription = "Renombrar",
                                tint = MetMusicColors.textSecondary,
                            )
                        }
                        IconButton(onClick = { onDeleteClick(playlist) }) {
                            Icon(
                                imageVector = Icons.Filled.Delete,
                                contentDescription = "Eliminar",
                                tint = MetMusicColors.textSecondary,
                            )
                        }
                    },
                    onClick = null,
                )
            }
        }
    }
}

@Composable
private fun FavoritesContent(
    favorites: List<Track>,
    onRemoveFavorite: (String) -> Unit,
    onGoToSearch: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    if (favorites.isEmpty()) {
        MetMusicEmptyState(
            title = "No tenés favoritos",
            subtitle = "Marcá canciones con el corazón desde su menú.",
            icon = Icons.Outlined.FavoriteBorder,
            actionLabel = "Buscar música",
            onAction = onGoToSearch,
        )
    } else {
        LazyColumn(
            contentPadding = PaddingValues(
                top = spacing.sm,
                bottom = spacing.listBottomInset,
            ),
        ) {
            items(favorites, key = { track -> track.trackId }) { track ->
                MetMusicListItem(
                    title = track.displayTitle,
                    subtitle = trackSubtitle(track),
                    leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl },
                    trailingContent = {
                        IconButton(onClick = { onRemoveFavorite(track.trackId) }) {
                            Icon(
                                imageVector = Icons.Filled.Favorite,
                                contentDescription = "Quitar de favoritos",
                                tint = MetMusicColors.accent,
                            )
                        }
                    },
                    onClick = null,
                )
            }
        }
    }
}

@Composable
private fun MixesContent(
    mixes: List<SavedMix>,
    onRemoveMix: (String) -> Unit,
    onGoToSearch: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    if (mixes.isEmpty()) {
        MetMusicEmptyState(
            title = "No tenés mixes guardados",
            subtitle = "Creá una estación desde el menú de cualquier canción.",
            icon = Icons.Outlined.PlayArrow,
            actionLabel = "Buscar música",
            onAction = onGoToSearch,
        )
    } else {
        LazyColumn(
            contentPadding = PaddingValues(
                top = spacing.sm,
                bottom = spacing.listBottomInset,
            ),
        ) {
            items(mixes, key = { savedMix -> savedMix.trackId }) { savedMix ->
                MixRow(
                    savedMix = savedMix,
                    onRemove = { onRemoveMix(savedMix.trackId) },
                )
            }
        }
    }
}

/** Fila de un mix guardado con menú de "Eliminar" (detalle en 6F). */
@Composable
private fun MixRow(
    savedMix: SavedMix,
    onRemove: () -> Unit,
) {
    var menuExpanded by remember { mutableStateOf(false) }
    MetMusicListItem(
        title = savedMix.mix.title,
        subtitle = savedMix.mix.subTitle ?: savedMix.mix.description,
        leadingUrl = savedMix.mix.imageUrl,
        trailingContent = {
            IconButton(onClick = { menuExpanded = true }) {
                Icon(
                    imageVector = Icons.Filled.MoreVert,
                    contentDescription = "Más opciones",
                    tint = MetMusicColors.textSecondary,
                )
            }
            DropdownMenu(
                expanded = menuExpanded,
                onDismissRequest = { menuExpanded = false },
            ) {
                DropdownMenuItem(
                    text = { Text(text = "Eliminar", style = MetMusicTextStyles.body) },
                    onClick = {
                        menuExpanded = false
                        onRemove()
                    },
                )
            }
        },
        onClick = null,
    )
}

@Composable
private fun HistoryContent(
    history: List<HistoryEntry>,
    onClearHistoryClick: () -> Unit,
    onGoToSearch: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    if (history.isEmpty()) {
        MetMusicEmptyState(
            title = "Sin historial",
            subtitle = "Las canciones que escuches van a aparecer acá.",
            icon = Icons.Outlined.DateRange,
            actionLabel = "Buscar música",
            onAction = onGoToSearch,
        )
    } else {
        Column {
            MetMusicSectionHeader(
                title = "Historial",
                actionLabel = "Limpiar",
                onAction = onClearHistoryClick,
            )
            LazyColumn(
                contentPadding = PaddingValues(bottom = spacing.listBottomInset),
            ) {
                items(history, key = { entry -> "${entry.trackId}-${entry.playedAt}" }) { entry ->
                    MetMusicListItem(
                        title = entry.title,
                        subtitle = entry.artist.takeIf { it.isNotEmpty() },
                        leadingUrl = entry.thumbnailUrl,
                        trailingContent = {
                            Text(
                                text = formatPlayedAt(entry.playedAt),
                                style = MetMusicTextStyles.rowTrailing,
                            )
                        },
                        onClick = null,
                    )
                }
            }
        }
    }
}

/** "Artista · Álbum" cuando hay datos; null si el track no trae ninguno. */
private fun trackSubtitle(track: Track): String? =
    listOfNotNull(track.artist, track.album).joinToString(" · ").takeIf { it.isNotEmpty() }

/** Antigüedad relativa de una reproducción; fecha corta a partir de 7 días. */
private fun formatPlayedAt(epochMillis: Long): String {
    val elapsed = System.currentTimeMillis() - epochMillis
    return when {
        elapsed < MINUTE_MS -> "hace un momento"
        elapsed < HOUR_MS -> "hace ${elapsed / MINUTE_MS} min"
        elapsed < DAY_MS -> "hace ${elapsed / HOUR_MS} h"
        elapsed < WEEK_MS -> "hace ${elapsed / DAY_MS} d"
        else -> playDateFormatter.format(
            Instant.ofEpochMilli(epochMillis).atZone(ZoneId.systemDefault()),
        )
    }
}

private const val MINUTE_MS = 60_000L
private const val HOUR_MS = 60 * MINUTE_MS
private const val DAY_MS = 24 * HOUR_MS
private const val WEEK_MS = 7 * DAY_MS

private val playDateFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("d MMM", Locale.forLanguageTag("es"))

/** Wrapper de previews: estado de muestra + callbacks no-op. */
@Composable
private fun LibraryContentPreview(state: LibraryUiState) {
    MetMusicTheme {
        LibraryScreenContent(
            state = state,
            snackbarHostState = remember { SnackbarHostState() },
            onTabSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onCreateClick = { /* no-op en preview */ },
            onRenameClick = { /* no-op en preview */ },
            onDeleteClick = { /* no-op en preview */ },
            onRemoveFavorite = { /* no-op en preview */ },
            onRemoveMix = { /* no-op en preview */ },
            onClearHistoryClick = { /* no-op en preview */ },
        )
    }
}

@Preview(
    name = "LibraryScreenContent · Playlists",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 640,
)
@Composable
private fun LibraryScreenContentPlaylistsPreview() {
    LibraryContentPreview(LibraryUiState.preview(LibraryTab.PLAYLISTS))
}

@Preview(
    name = "LibraryScreenContent · Favoritos",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 640,
)
@Composable
private fun LibraryScreenContentFavoritesPreview() {
    LibraryContentPreview(LibraryUiState.preview(LibraryTab.FAVORITES))
}

@Preview(
    name = "LibraryScreenContent · Mixes",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 640,
)
@Composable
private fun LibraryScreenContentMixesPreview() {
    LibraryContentPreview(LibraryUiState.preview(LibraryTab.MIXES))
}

@Preview(
    name = "LibraryScreenContent · Historial",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 640,
)
@Composable
private fun LibraryScreenContentHistoryPreview() {
    LibraryContentPreview(LibraryUiState.preview(LibraryTab.HISTORY))
}

@Preview(
    name = "LibraryScreenContent · vacía",
    showBackground = true,
    backgroundColor = 0xFF000000,
    heightDp = 640,
)
@Composable
private fun LibraryScreenContentEmptyPreview() {
    LibraryContentPreview(LibraryUiState(isLoading = false))
}
