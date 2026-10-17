package com.metmusic.metmusic.feature.home

import androidx.compose.foundation.Image
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.ExploreSectionType
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.ui.components.MetMusicAlbumCard
import com.metmusic.metmusic.core.ui.components.MetMusicArtistCard
import com.metmusic.metmusic.core.ui.components.MetMusicChip
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState
import com.metmusic.metmusic.core.ui.components.MetMusicErrorState
import com.metmusic.metmusic.core.ui.components.MetMusicListItem
import com.metmusic.metmusic.core.ui.components.MetMusicPlaylistCard
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.components.MetMusicShimmer
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Home real (6B): explore + novedades + charts + moods + historial reciente,
 * con pull to refresh, fallback offline, skeleton, empty y error states.
 * 6E-1 conecta la navegación a las details y la reproducción de tracks.
 */
@Composable
fun HomeScreen(
    onGoToSearch: () -> Unit,
    onAlbumClick: (String) -> Unit,
    onArtistClick: (String) -> Unit,
    onPlaylistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    HomeScreenContent(
        state = state,
        onMoodSelected = viewModel::onMoodSelected,
        onRefresh = viewModel::refresh,
        onRetry = viewModel::retry,
        onGoToSearch = onGoToSearch,
        onAlbumClick = onAlbumClick,
        onArtistClick = onArtistClick,
        onPlaylistClick = onPlaylistClick,
        onPlayTracks = onPlayTracks,
        modifier = modifier,
    )
}

/** Composición pura de la Home (sin ViewModel), lista para previews. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreenContent(
    state: HomeUiState,
    onMoodSelected: (String?) -> Unit,
    onRefresh: () -> Unit,
    onRetry: () -> Unit,
    onGoToSearch: () -> Unit,
    onAlbumClick: (String) -> Unit,
    onArtistClick: (String) -> Unit,
    onPlaylistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val error = state.error
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
    ) {
        when {
            state.isLoading && state.isEmpty -> HomeSkeleton()
            error != null && state.isEmpty -> MetMusicErrorState(
                message = error,
                onRetry = onRetry,
            )
            state.isEmpty -> MetMusicEmptyState(
                title = "Tu Home está vacía",
                subtitle = "Explorá artistas, álbumes y playlists desde la búsqueda.",
                icon = Icons.Outlined.Home,
                actionLabel = "Buscar música",
                onAction = onGoToSearch,
            )
            else -> HomeList(
                state = state,
                onMoodSelected = onMoodSelected,
                onRefresh = onRefresh,
                onAlbumClick = onAlbumClick,
                onArtistClick = onArtistClick,
                onPlaylistClick = onPlaylistClick,
                onPlayTracks = onPlayTracks,
            )
        }
    }
}

/** Lista scrolleable de la Home con pull to refresh. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun HomeList(
    state: HomeUiState,
    onMoodSelected: (String?) -> Unit,
    onRefresh: () -> Unit,
    onAlbumClick: (String) -> Unit,
    onArtistClick: (String) -> Unit,
    onPlaylistClick: (String) -> Unit,
    onPlayTracks: (List<Track>, Int) -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    PullToRefreshBox(
        isRefreshing = state.isRefreshing,
        onRefresh = onRefresh,
        modifier = Modifier.fillMaxSize(),
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = spacing.listBottomInset),
        ) {
            item(key = "moods") {
                HomeMoodSelector(
                    selectedMood = state.selectedMood,
                    onMoodSelected = onMoodSelected,
                )
            }
            if (state.offline) {
                item(key = "offline") { OfflineBanner() }
            }
            if (state.recent.isNotEmpty()) {
                item(key = "recent-header") {
                    MetMusicSectionHeader(title = "Escuchado recientemente")
                }
                items(state.recent.take(5), key = { "${it.trackId}-${it.playedAt}" }) { entry ->
                    MetMusicListItem(
                        title = entry.title,
                        subtitle = entry.artist.ifEmpty { null },
                        leadingUrl = entry.thumbnailUrl.ifEmpty { null },
                        onClick = null,
                    )
                }
                item(key = "recent-gap") { SectionSpacer() }
            }
            if (state.newReleases.isNotEmpty()) {
                item(key = "new-releases-header") {
                    MetMusicSectionHeader(title = "Nuevos lanzamientos")
                }
                item(key = "new-releases-row") {
                    LazyRow(
                        contentPadding = PaddingValues(horizontal = spacing.pagePadding),
                        horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
                    ) {
                        items(state.newReleases, key = { it.albumId }) { album ->
                            MetMusicAlbumCard(
                                album = album,
                                onClick = { onAlbumClick(album.albumId) },
                            )
                        }
                    }
                }
                item(key = "new-releases-gap") { SectionSpacer() }
            }
            if (state.charts.isNotEmpty()) {
                item(key = "charts-header") {
                    MetMusicSectionHeader(title = "Top charts")
                }
                itemsIndexed(
                    items = state.charts.take(5),
                    key = { _, track -> track.trackId },
                ) { index, track ->
                    TrackRow(
                        track = track,
                        onClick = { onPlayTracks(state.charts, index) },
                    )
                }
                item(key = "charts-gap") { SectionSpacer() }
            }
            state.explore.sections.forEach { section ->
                if (section.isEmpty) return@forEach
                item(key = "header-${section.id}") {
                    MetMusicSectionHeader(title = section.title)
                }
                when (section.type) {
                    ExploreSectionType.TRACKS -> itemsIndexed(
                        items = section.tracks.take(10),
                        key = { _, track -> "section-${section.id}-${track.trackId}" },
                    ) { index, track ->
                        TrackRow(
                            track = track,
                            onClick = { onPlayTracks(section.tracks, index) },
                        )
                    }
                    ExploreSectionType.ALBUMS -> item(key = "row-${section.id}") {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = spacing.pagePadding),
                            horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
                        ) {
                            items(section.albums, key = { "${section.id}-${it.albumId}" }) { album ->
                                MetMusicAlbumCard(
                                    album = album,
                                    onClick = { onAlbumClick(album.albumId) },
                                )
                            }
                        }
                    }
                    ExploreSectionType.ARTISTS -> item(key = "row-${section.id}") {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = spacing.pagePadding),
                            horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
                        ) {
                            items(section.artists, key = { "${section.id}-${it.artistId}" }) { artist ->
                                MetMusicArtistCard(
                                    artist = artist,
                                    onClick = { onArtistClick(artist.artistId) },
                                )
                            }
                        }
                    }
                    ExploreSectionType.PLAYLISTS -> item(key = "row-${section.id}") {
                        LazyRow(
                            contentPadding = PaddingValues(horizontal = spacing.pagePadding),
                            horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
                        ) {
                            items(
                                items = section.playlists,
                                key = { "${section.id}-${it.playlistId}" },
                            ) { playlist ->
                                MetMusicPlaylistCard(
                                    playlist = playlist,
                                    onClick = { onPlaylistClick(playlist.playlistId) },
                                )
                            }
                        }
                    }
                    ExploreSectionType.UNKNOWN -> Unit
                }
                item(key = "gap-${section.id}") { SectionSpacer() }
            }
        }
    }
}

/** Chips de moods: "Todos" (null) + los moods de Explore. */
@Composable
private fun HomeMoodSelector(
    selectedMood: String?,
    onMoodSelected: (String?) -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .horizontalScroll(rememberScrollState())
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
        horizontalArrangement = Arrangement.spacedBy(spacing.sm),
    ) {
        MetMusicChip(
            label = "Todos",
            selected = selectedMood == null,
            onClick = { onMoodSelected(null) },
        )
        HomeMood.entries.forEach { mood ->
            MetMusicChip(
                label = mood.label,
                selected = selectedMood == mood.value,
                onClick = { onMoodSelected(mood.value) },
            )
        }
    }
}

/** Banner de modo offline: explore falló pero hay historial local. */
@Composable
private fun OfflineBanner() {
    val spacing = LocalMetMusicSpacing.current
    val shape = RoundedCornerShape(LocalMetMusicRadius.current.md)
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.pagePadding, vertical = spacing.xs)
            .clip(shape)
            .background(MetMusicColors.controlFill)
            .padding(horizontal = spacing.md, vertical = spacing.sm),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(spacing.sm),
    ) {
        Image(
            imageVector = Icons.Outlined.Warning,
            contentDescription = null,
            colorFilter = ColorFilter.tint(MetMusicColors.warning),
            modifier = Modifier.size(spacing.lg),
        )
        Text(
            text = "Sin conexión. Mostrando historial local.",
            style = MetMusicTextStyles.bodyLight,
            color = MetMusicColors.textSecondary,
        )
    }
}

/** Skeleton de la primera carga: moods + carrusel + filas. */
@Composable
private fun HomeSkeleton() {
    val spacing = LocalMetMusicSpacing.current
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(vertical = spacing.md),
        verticalArrangement = Arrangement.spacedBy(spacing.md),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
            horizontalArrangement = Arrangement.spacedBy(spacing.sm),
        ) {
            repeat(4) {
                MetMusicShimmer(
                    modifier = Modifier
                        .width(72.dp)
                        .height(32.dp),
                    shape = RoundedCornerShape(LocalMetMusicRadius.current.chip),
                )
            }
        }
        Row(
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
            horizontalArrangement = Arrangement.spacedBy(spacing.itemGap),
        ) {
            repeat(3) {
                MetMusicShimmer(modifier = Modifier.size(140.dp))
            }
        }
        Column(
            modifier = Modifier.padding(horizontal = spacing.pagePadding),
            verticalArrangement = Arrangement.spacedBy(spacing.sm),
        ) {
            repeat(3) {
                MetMusicShimmer(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                )
            }
        }
    }
}

/** Fila de track (charts y secciones de Explore): toca y reproduce su cola. */
@Composable
private fun TrackRow(track: Track, onClick: () -> Unit) {
    MetMusicListItem(
        title = track.displayTitle,
        subtitle = trackSubtitle(track),
        trailing = formatDuration(track),
        leadingUrl = track.listThumbnailUrl.ifEmpty { track.thumbnailUrl }.ifEmpty { null },
        onClick = onClick,
    )
}

/** Separador vertical entre secciones de la Home. */
@Composable
private fun SectionSpacer() {
    Spacer(modifier = Modifier.height(LocalMetMusicSpacing.current.sectionGap))
}

/** "Artista · Álbum" o null cuando el track no trae ninguno. */
private fun trackSubtitle(track: Track): String? =
    listOfNotNull(
        track.artist?.takeIf { it.isNotBlank() },
        track.album?.takeIf { it.isNotBlank() },
    ).joinToString(" · ").ifEmpty { null }

/** "m:ss" para la duración; null cuando el track no la trae. */
private fun formatDuration(track: Track): String? {
    if (track.durationSeconds <= 0) return null
    return "%d:%02d".format(track.durationSeconds / 60, track.durationSeconds % 60)
}

@Preview(name = "Home con datos", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun HomeScreenContentPreview() {
    MetMusicTheme {
        HomeScreenContent(
            state = HomeUiState.preview(),
            onMoodSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlaylistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
        )
    }
}

@Preview(name = "Home cargando", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun HomeScreenContentPreviewLoading() {
    MetMusicTheme {
        HomeScreenContent(
            state = HomeUiState(),
            onMoodSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlaylistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
        )
    }
}

@Preview(name = "Home vacía", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun HomeScreenContentPreviewEmpty() {
    MetMusicTheme {
        HomeScreenContent(
            state = HomeUiState(isLoading = false),
            onMoodSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlaylistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
        )
    }
}

@Preview(name = "Home error", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun HomeScreenContentPreviewError() {
    MetMusicTheme {
        HomeScreenContent(
            state = HomeUiState(isLoading = false, error = "Sin conexión al servidor"),
            onMoodSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlaylistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
        )
    }
}

@Preview(name = "Home offline", showBackground = true, backgroundColor = 0xFF000000, widthDp = 360, heightDp = 640)
@Composable
private fun HomeScreenContentPreviewOffline() {
    MetMusicTheme {
        HomeScreenContent(
            state = HomeUiState.previewOffline(),
            onMoodSelected = { /* no-op en preview */ },
            onRefresh = { /* no-op en preview */ },
            onRetry = { /* no-op en preview */ },
            onGoToSearch = { /* no-op en preview */ },
            onAlbumClick = { /* no-op en preview */ },
            onArtistClick = { /* no-op en preview */ },
            onPlaylistClick = { /* no-op en preview */ },
            onPlayTracks = { _, _ -> /* no-op en preview */ },
        )
    }
}
