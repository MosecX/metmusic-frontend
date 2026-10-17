package com.metmusic.metmusic.feature.search

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import coil3.compose.AsyncImage
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.theme.MetMusicColors
import com.metmusic.metmusic.core.ui.theme.MetMusicTextStyles

/**
 * Pantalla de búsqueda: campo con debounce (en el ViewModel), pestañas por
 * tipo y lista de resultados agrupada. Los rows son display-only: tocar un
 * resultado abrirá su detalle en otra fase.
 */
@Composable
fun SearchScreen(viewModel: SearchViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
    ) {
        SearchBar(query = state.query, onQueryChange = viewModel::onQueryChange)
        SearchTypeRow(selected = state.type, onSelect = viewModel::onTypeChange)
        when {
            state.showEmptyPrompt -> EmptyPrompt("Buscá artistas, álbumes, canciones o playlists.")
            state.isLoading -> LoadingBlock()
            state.error != null -> state.error?.let { message ->
                ErrorBlock(message = message, onRetry = viewModel::retry)
            }
            state.showNoResults -> EmptyPrompt("Sin resultados para \"${state.query.trim()}\".")
            else -> ResultsContent(state)
        }
    }
}

/** Campo de búsqueda con ícono de lupa y botón de limpiar. */
@Composable
private fun SearchBar(query: String, onQueryChange: (String) -> Unit) {
    OutlinedTextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        placeholder = { Text("Buscar en MetMusic", color = MetMusicColors.textTertiary) },
        leadingIcon = {
            Icon(
                imageVector = Icons.Filled.Search,
                contentDescription = null,
                tint = MetMusicColors.textSecondary,
            )
        },
        trailingIcon = {
            if (query.isNotEmpty()) {
                IconButton(onClick = { onQueryChange("") }) {
                    Icon(
                        imageVector = Icons.Filled.Close,
                        contentDescription = "Limpiar búsqueda",
                        tint = MetMusicColors.textSecondary,
                    )
                }
            }
        },
        singleLine = true,
        shape = RoundedCornerShape(12.dp),
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = MetMusicColors.controlFill,
            unfocusedContainerColor = MetMusicColors.controlFill,
            focusedBorderColor = MetMusicColors.glassBorder,
            unfocusedBorderColor = MetMusicColors.glassBorder,
            focusedTextColor = MetMusicColors.textPrimary,
            unfocusedTextColor = MetMusicColors.textPrimary,
            cursorColor = MetMusicColors.accent,
        ),
    )
}

/** Pestañas de tipo de resultado (scroll horizontal). */
@Composable
private fun SearchTypeRow(selected: SearchType, onSelect: (SearchType) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        SearchType.entries.forEach { type ->
            FilterChip(
                selected = type == selected,
                onClick = { onSelect(type) },
                label = { Text(type.label) },
                shape = RoundedCornerShape(20.dp),
                colors = FilterChipDefaults.filterChipColors(
                    containerColor = MetMusicColors.controlFill,
                    labelColor = MetMusicColors.textPrimary,
                    selectedContainerColor = MetMusicColors.accent,
                    selectedLabelColor = Color.Black,
                ),
            )
        }
    }
}

/** Lista de resultados; en `ALL` agrupa por secciones. */
@Composable
private fun ResultsContent(state: SearchState) {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(top = 8.dp, bottom = 24.dp),
    ) {
        when (state.type) {
            SearchType.ALL -> {
                if (state.results.tracks.isNotEmpty()) {
                    item { SectionHeader("Canciones") }
                    items(state.results.tracks) { track -> TrackRow(track) }
                }
                if (state.results.albums.isNotEmpty()) {
                    item { SectionHeader("Álbumes") }
                    items(state.results.albums) { album -> AlbumRow(album) }
                }
                if (state.results.artists.isNotEmpty()) {
                    item { SectionHeader("Artistas") }
                    items(state.results.artists) { artist -> ArtistRow(artist) }
                }
                if (state.results.playlists.isNotEmpty()) {
                    item { SectionHeader("Playlists") }
                    items(state.results.playlists) { playlist -> PlaylistRow(playlist) }
                }
            }
            SearchType.TRACKS -> items(state.results.tracks) { track -> TrackRow(track) }
            SearchType.ALBUMS -> items(state.results.albums) { album -> AlbumRow(album) }
            SearchType.ARTISTS -> items(state.results.artists) { artist -> ArtistRow(artist) }
            SearchType.PLAYLISTS -> items(state.results.playlists) { playlist -> PlaylistRow(playlist) }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MetMusicTextStyles.sectionTitle,
        color = MetMusicColors.textPrimary,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
    )
}

@Composable
private fun TrackRow(track: Track) {
    val subtitle = listOfNotNull(track.artist, track.album).joinToString(" · ")
    val trailing = if (track.durationSeconds > 0) formatDuration(track.durationSeconds) else null
    SearchRow(
        imageUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl },
        title = track.title,
        subtitle = subtitle,
        trailing = trailing,
    )
}

@Composable
private fun AlbumRow(album: Album) {
    val subtitle = listOfNotNull(album.artist, album.year.ifEmpty { null }).joinToString(" · ")
    SearchRow(
        imageUrl = album.thumbnailUrl,
        title = album.title,
        subtitle = subtitle,
    )
}

@Composable
private fun ArtistRow(artist: Artist) {
    SearchRow(
        imageUrl = artist.imageUrl,
        title = artist.name,
        subtitle = "",
    )
}

@Composable
private fun PlaylistRow(playlist: Playlist) {
    SearchRow(
        imageUrl = playlist.thumbnailUrl,
        title = playlist.title,
        subtitle = playlist.creator ?: "${playlist.trackCount} canciones",
    )
}

/** Fila base: miniatura 56 dp + título/subtítulo + trailing opcional. */
@Composable
private fun SearchRow(
    imageUrl: String,
    title: String,
    subtitle: String,
    trailing: String? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        RowThumbnail(url = imageUrl)
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MetMusicTextStyles.rowTitle,
                color = MetMusicColors.textPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (subtitle.isNotEmpty()) {
                Text(
                    text = subtitle,
                    style = MetMusicTextStyles.rowSubtitle,
                    color = MetMusicColors.textSecondary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (trailing != null) {
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = trailing,
                style = MetMusicTextStyles.rowTrailing,
                color = MetMusicColors.textTertiary,
            )
        }
    }
}

/** Miniatura de fila; cae a un bloque `controlFill` cuando no hay URL. */
@Composable
private fun RowThumbnail(url: String) {
    if (url.isNotEmpty()) {
        AsyncImage(
            model = url,
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier
                .size(56.dp)
                .clip(RoundedCornerShape(12.dp)),
        )
    } else {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(MetMusicColors.controlFill),
        )
    }
}

@Composable
private fun LoadingBlock() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        CircularProgressIndicator(color = MetMusicColors.accent)
    }
}

@Composable
private fun EmptyPrompt(text: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = text,
            style = MetMusicTextStyles.subtitle,
            color = MetMusicColors.textSecondary,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun ErrorBlock(message: String, onRetry: () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = message,
                style = MetMusicTextStyles.subtitle,
                color = MetMusicColors.textSecondary,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(12.dp))
            TextButton(
                onClick = onRetry,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.accent),
            ) {
                Text("Reintentar")
            }
        }
    }
}

/** Formatea segundos como mm:ss. */
private fun formatDuration(seconds: Int): String =
    "%d:%02d".format(seconds / 60, seconds % 60)
