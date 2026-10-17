package com.metmusic.metmusic.feature.userplaylist.addtracks

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.components.MetMusicTextField
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Picker modal de canciones (6E-2). Se monta como [Dialog] full-screen
 * embebido en [com.metmusic.metmusic.feature.userplaylist.UserPlaylistScreen]
 * (no es una ruta propia): busca con debounce, permite seleccionar varias
 * canciones y confirma con la lista de ids.
 */
@Composable
fun AddTracksScreen(
    onDismiss: () -> Unit,
    onConfirm: (List<String>) -> Unit,
    viewModel: AddTracksViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val dismiss = {
        viewModel.reset()
        onDismiss()
    }
    val confirm = {
        onConfirm(state.selected.toList())
        viewModel.reset()
    }
    Dialog(
        onDismissRequest = dismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MetMusicColors.background,
        ) {
            AddTracksScreenContent(
                state = state,
                onQueryChange = viewModel::onQueryChange,
                onToggleSelection = viewModel::toggleSelection,
                onConfirm = confirm,
                onDismiss = dismiss,
                onRetry = viewModel::retry,
            )
        }
    }
}

/** Composición pura del picker (sin ViewModel), para previews. */
@Composable
fun AddTracksScreenContent(
    state: AddTracksViewModel.State,
    onQueryChange: (String) -> Unit,
    onToggleSelection: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val radius = LocalMetMusicRadius.current
    val error = state.error
    Scaffold(
        modifier = modifier
            .fillMaxSize()
            .safeDrawingPadding(),
        containerColor = MetMusicColors.background,
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = spacing.sm, vertical = spacing.sm),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "Cerrar",
                    )
                }
                Text(
                    text = "Agregar canciones",
                    style = MetMusicTextStyles.title,
                    modifier = Modifier.padding(start = spacing.xs),
                )
            }
        },
        bottomBar = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
            ) {
                Button(
                    onClick = onConfirm,
                    enabled = state.selected.isNotEmpty(),
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MetMusicColors.accent,
                        contentColor = Color.Black,
                    ),
                    shape = RoundedCornerShape(radius.md),
                ) {
                    Text(
                        text = "Agregar (${state.selected.size})",
                        style = MetMusicTextStyles.button.copy(color = Color.Unspecified),
                    )
                }
            }
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize(),
        ) {
            MetMusicTextField(
                value = state.query,
                onValueChange = onQueryChange,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = spacing.pagePadding, vertical = spacing.sm),
                placeholder = "Buscar canciones",
                leadingIcon = Icons.Filled.Search,
            )
            when {
                state.isLoading -> MetMusicLoading()
                error != null -> MetMusicErrorState(message = error, onRetry = onRetry)
                state.query.isBlank() -> MetMusicEmptyState(
                    title = "Buscá canciones",
                    subtitle = "Elegí las que quieras agregar a la playlist.",
                    icon = Icons.Filled.Search,
                )
                state.results.isEmpty() -> MetMusicEmptyState(
                    title = "Sin resultados",
                    subtitle = "No encontramos nada para \"${state.query.trim()}\".",
                    icon = Icons.Filled.Search,
                )
                else -> LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(state.results, key = { track -> track.trackId }) { track ->
                        MetMusicListItem(
                            title = track.displayTitle,
                            subtitle = track.artist,
                            leadingUrl = track.listThumbnailUrl
                                .ifEmpty { track.thumbnailUrl }
                                .ifEmpty { null },
                            trailingContent = {
                                Checkbox(
                                    checked = track.trackId in state.selected,
                                    onCheckedChange = { onToggleSelection(track.trackId) },
                                    colors = CheckboxDefaults.colors(
                                        checkedColor = MetMusicColors.accent,
                                        uncheckedColor = MetMusicColors.textSecondary,
                                        checkmarkColor = Color.Black,
                                    ),
                                )
                            },
                            onClick = { onToggleSelection(track.trackId) },
                        )
                    }
                    item {
                        Spacer(modifier = Modifier.height(spacing.listBottomInset))
                    }
                }
            }
        }
    }
}

private val previewResults: List<Track> = listOf(
    Track(
        trackId = "preview-add-track-1",
        title = "One More Time",
        artist = "Daft Punk",
        album = "Discovery",
        durationSeconds = 320,
    ),
    Track(
        trackId = "preview-add-track-2",
        title = "Around the World",
        artist = "Daft Punk",
        album = "Homework",
        durationSeconds = 429,
    ),
    Track(
        trackId = "preview-add-track-3",
        title = "Instant Crush",
        artist = "Daft Punk",
        album = "Random Access Memories",
        durationSeconds = 337,
    ),
)

/** Wrapper de previews: tema + contenido con callbacks no-op. */
@Composable
private fun AddTracksPreview(state: AddTracksViewModel.State) {
    MetMusicTheme {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(MetMusicColors.background),
        ) {
            AddTracksScreenContent(
                state = state,
                onQueryChange = { /* no-op en preview */ },
                onToggleSelection = { /* no-op en preview */ },
                onConfirm = { /* no-op en preview */ },
                onDismiss = { /* no-op en preview */ },
                onRetry = { /* no-op en preview */ },
            )
        }
    }
}

@Preview(
    name = "AddTracks · resultados con selección",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AddTracksResultsPreview() {
    AddTracksPreview(
        AddTracksViewModel.State(
            query = "daft punk",
            results = previewResults,
            selected = setOf("preview-add-track-1", "preview-add-track-3"),
        ),
    )
}

@Preview(
    name = "AddTracks · vacío",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AddTracksEmptyPreview() {
    AddTracksPreview(AddTracksViewModel.State())
}

@Preview(
    name = "AddTracks · loading",
    showBackground = true,
    backgroundColor = 0xFF000000,
    widthDp = 360,
    heightDp = 720,
)
@Composable
private fun AddTracksLoadingPreview() {
    AddTracksPreview(
        AddTracksViewModel.State(query = "daft punk", isLoading = true),
    )
}
