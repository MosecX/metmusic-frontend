package com.metmusic.metmusic.feature.search

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.Search
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.model.SearchResults
import com.metmusic.metmusic.core.model.SearchType
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicChip
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicLoading
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.components.MetMusicTextField
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Pantalla de búsqueda: campo con debounce (en el ViewModel), pestañas por
 * tipo y lista de resultados agrupada. Tocar un track lo reproduce
 * (PlayerConnection); álbumes, artistas y playlists siguen display-only.
 */
@Composable
fun SearchScreen(viewModel: SearchViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    SearchScreenContent(
        state = state,
        onQueryChange = viewModel::onQueryChange,
        onTypeChange = viewModel::onTypeChange,
        onRetry = viewModel::retry,
        onTrackClick = viewModel::playTrackAt,
    )
}

/** Composición pura de la búsqueda (sin ViewModel), lista para previews. */
@Composable
fun SearchScreenContent(
    state: SearchState,
    onQueryChange: (String) -> Unit,
    onTypeChange: (SearchType) -> Unit,
    onRetry: () -> Unit,
    onTrackClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
    ) {
        SearchBar(query = state.query, onQueryChange = onQueryChange)
        SearchTypeRow(selected = state.type, onSelect = onTypeChange)
        when {
            state.showEmptyPrompt -> MetMusicEmptyState(
                title = "Buscá en MetMusic",
                subtitle = "Artistas, álbumes, canciones o playlists.",
                icon = Icons.Outlined.Search,
            )
            state.isLoading -> MetMusicLoading(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = LocalMetMusicSpacing.current.xl),
            )
            state.error != null -> state.error?.let { message ->
                MetMusicErrorState(message = message, onRetry = onRetry)
            }
            state.showNoResults -> MetMusicEmptyState(
                title = "Sin resultados",
                subtitle = "No encontramos nada para \"${state.query.trim()}\".",
                icon = Icons.Outlined.Search,
            )
            else -> ResultsContent(state = state, onTrackClick = onTrackClick)
        }
    }
}

/** Campo de búsqueda con lupa, texto guía y botón de limpiar. */
@Composable
private fun SearchBar(query: String, onQueryChange: (String) -> Unit) {
    MetMusicTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                horizontal = LocalMetMusicSpacing.current.pagePadding,
                vertical = LocalMetMusicSpacing.current.sm,
            ),
        placeholder = "Buscar en MetMusic",
        leadingIcon = Icons.Filled.Search,
        trailingIcon = if (query.isNotEmpty()) Icons.Filled.Close else null,
        onTrailingIconClick = { onQueryChange("") },
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
    )
}

/** Pestañas de tipo de resultado (scroll horizontal). */
@Composable
private fun SearchTypeRow(selected: SearchType, onSelect: (SearchType) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(
                horizontal = LocalMetMusicSpacing.current.pagePadding,
                vertical = LocalMetMusicSpacing.current.xs,
            ),
        horizontalArrangement = Arrangement.spacedBy(LocalMetMusicSpacing.current.sm),
    ) {
        SearchType.entries.forEach { type ->
            MetMusicChip(
                label = type.label,
                selected = type == selected,
                onClick = { onSelect(type) },
            )
        }
    }
}

/** Lista de resultados; en `ALL` agrupa por secciones. */
@Composable
private fun ResultsContent(state: SearchState, onTrackClick: (Int) -> Unit) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(
            top = LocalMetMusicSpacing.current.sm,
            bottom = LocalMetMusicSpacing.current.xl,
        ),
    ) {
        when (state.type) {
            SearchType.ALL -> {
                if (state.results.tracks.isNotEmpty()) {
                    item { MetMusicSectionHeader(title = "Canciones") }
                    itemsIndexed(
                        items = state.results.tracks,
                        key = { _, track -> track.trackId },
                    ) { index, track ->
                        TrackRow(track = track, onClick = { onTrackClick(index) })
                    }
                }
                if (state.results.albums.isNotEmpty()) {
                    item { MetMusicSectionHeader(title = "Álbumes") }
                    items(state.results.albums) { album -> AlbumRow(album) }
                }
                if (state.results.artists.isNotEmpty()) {
                    item { MetMusicSectionHeader(title = "Artistas") }
                    items(state.results.artists) { artist -> ArtistRow(artist) }
                }
                if (state.results.playlists.isNotEmpty()) {
                    item { MetMusicSectionHeader(title = "Playlists") }
                    items(state.results.playlists) { playlist -> PlaylistRow(playlist) }
                }
            }
            SearchType.TRACKS -> itemsIndexed(
                items = state.results.tracks,
                key = { _, track -> track.trackId },
            ) { index, track ->
                TrackRow(track = track, onClick = { onTrackClick(index) })
            }
            SearchType.ALBUMS -> items(state.results.albums) { album -> AlbumRow(album) }
            SearchType.ARTISTS -> items(state.results.artists) { artist -> ArtistRow(artist) }
            SearchType.PLAYLISTS -> items(state.results.playlists) { playlist -> PlaylistRow(playlist) }
        }
    }
}

@Composable
private fun TrackRow(track: Track, onClick: () -> Unit) {
    MetMusicListItem(
        title = track.displayTitle,
        subtitle = "${track.artist ?: ""} · ${track.album ?: ""}".trim('·', ' '),
        trailing = if (track.durationSeconds > 0) formatDuration(track.durationSeconds) else null,
        leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl },
        onClick = onClick,
    )
}

@Composable
private fun AlbumRow(album: Album) {
    MetMusicListItem(
        title = album.title,
        subtitle = "${album.artist ?: ""} · ${album.year}".trim('·', ' '),
        leadingUrl = album.thumbnailUrl,
    )
}

@Composable
private fun ArtistRow(artist: Artist) {
    MetMusicListItem(
        title = artist.name,
        leadingUrl = artist.imageUrl,
    )
}

@Composable
private fun PlaylistRow(playlist: Playlist) {
    MetMusicListItem(
        title = playlist.title,
        subtitle = playlist.creator ?: "${playlist.trackCount} canciones",
        leadingUrl = playlist.thumbnailUrl,
    )
}

/** Formatea segundos como mm:ss. */
private fun formatDuration(seconds: Int): String =
    "%d:%02d".format(seconds / 60, seconds % 60)

@Preview(name = "SearchResults", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun SearchResultsPreview() {
    MetMusicTheme {
        ResultsContent(
            state = SearchState(
                query = "daft punk",
                results = SearchResults(
                    tracks = listOf(
                        Track(
                            trackId = "1",
                            title = "One More Time",
                            artist = "Daft Punk",
                            album = "Discovery",
                            durationSeconds = 320,
                        ),
                        Track(
                            trackId = "2",
                            title = "Instant Crush",
                            artist = "Daft Punk",
                            album = "Random Access Memories",
                            durationSeconds = 337,
                        ),
                    ),
                ),
            ),
            onTrackClick = {},
        )
    }
}

@Preview(name = "SearchEmpty", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun SearchScreenEmptyPreview() {
    MetMusicTheme {
        SearchScreenContent(
            state = SearchState(),
            onQueryChange = {},
            onTypeChange = {},
            onRetry = {},
            onTrackClick = {},
        )
    }
}

@Preview(name = "SearchNoResults", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun SearchScreenNoResultsPreview() {
    MetMusicTheme {
        SearchScreenContent(
            state = SearchState(query = "zzzz"),
            onQueryChange = {},
            onTypeChange = {},
            onRetry = {},
            onTrackClick = {},
        )
    }
}

@Preview(name = "SearchError", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun SearchScreenErrorPreview() {
    MetMusicTheme {
        SearchScreenContent(
            state = SearchState(query = "daft punk", error = "No se pudo conectar con el servidor."),
            onQueryChange = {},
            onTypeChange = {},
            onRetry = {},
            onTrackClick = {},
        )
    }
}
