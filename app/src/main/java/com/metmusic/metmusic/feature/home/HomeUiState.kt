package com.metmusic.metmusic.feature.home

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.model.ExploreHome
import com.metmusic.metmusic.core.model.ExploreSection
import com.metmusic.metmusic.core.model.ExploreSectionType
import com.metmusic.metmusic.core.model.HistoryEntry
import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.model.Track

/**
 * Moods de Explore de la Home.
 *
 * Port del `ExploreMood` de Flutter
 * (`old-flutter/lib/services/api/explore_service.dart`): el modelo Kotlin no
 * tenía el enum, así que vive local a la feature. `value` viaja al query
 * param `mood`; `label` se muestra en los chips.
 */
enum class HomeMood(val value: String, val label: String) {
    CHILL("chill", "Chill"),
    WORKOUT("workout", "Workout"),
    FOCUS("focus", "Focus"),
    PARTY("party", "Party"),
}

/** Snapshot inmutable de la Home para la UI. */
@Immutable
data class HomeUiState(
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val explore: ExploreHome = ExploreHome(),
    val newReleases: List<Album> = emptyList(),
    val charts: List<Track> = emptyList(),
    val recent: List<HistoryEntry> = emptyList(),
    val selectedMood: String? = null,
    val offline: Boolean = false,
    val error: String? = null,
) {
    /** `true` cuando no hay ningún contenido para mostrar. */
    val isEmpty: Boolean
        get() = explore.isEmpty && newReleases.isEmpty && charts.isEmpty && recent.isEmpty

    companion object {
        /** Estado de muestra con datos, solo para previews (sin red). */
        fun preview(): HomeUiState = HomeUiState(
            isLoading = false,
            explore = ExploreHome(sections = previewSections()),
            newReleases = previewAlbums(),
            charts = previewTracks(),
            recent = emptyList(),
        )

        /** Variante offline del preview: banner visible + historial local. */
        fun previewOffline(): HomeUiState = preview().copy(
            offline = true,
            recent = previewRecent(),
        )
    }
}

private fun previewAlbums(): List<Album> = listOf(
    Album(albumId = "preview-album-1", title = "Discovery", artist = "Daft Punk"),
    Album(albumId = "preview-album-2", title = "Random Access Memories", artist = "Daft Punk"),
    Album(albumId = "preview-album-3", title = "Homework", artist = "Daft Punk"),
)

private fun previewTracks(): List<Track> = listOf(
    Track(
        trackId = "preview-track-1",
        title = "One More Time",
        artist = "Daft Punk",
        album = "Discovery",
        durationSeconds = 320,
    ),
    Track(
        trackId = "preview-track-2",
        title = "Around the World",
        artist = "Daft Punk",
        album = "Homework",
        durationSeconds = 429,
    ),
    Track(
        trackId = "preview-track-3",
        title = "Instant Crush",
        artist = "Daft Punk",
        album = "Random Access Memories",
        durationSeconds = 337,
    ),
)

private fun previewArtists(): List<Artist> = listOf(
    Artist(artistId = "preview-artist-1", name = "Daft Punk"),
    Artist(artistId = "preview-artist-2", name = "Breakbot"),
    Artist(artistId = "preview-artist-3", name = "Kavinsky"),
)

private fun previewPlaylists(): List<Playlist> = listOf(
    Playlist(
        playlistId = "preview-playlist-1",
        title = "French Touch",
        creator = "MetMusic",
        numberOfTracks = 42,
    ),
    Playlist(playlistId = "preview-playlist-2", title = "Noche", numberOfTracks = 18),
    Playlist(
        playlistId = "preview-playlist-3",
        title = "Focus",
        creator = "MetMusic",
        numberOfTracks = 30,
    ),
)

private fun previewSections(): List<ExploreSection> = listOf(
    ExploreSection(
        id = "explore_artists",
        title = "Artistas para vos",
        type = ExploreSectionType.ARTISTS,
        artists = previewArtists(),
    ),
    ExploreSection(
        id = "explore_playlists",
        title = "Playlists destacadas",
        type = ExploreSectionType.PLAYLISTS,
        playlists = previewPlaylists(),
    ),
)

private fun previewRecent(): List<HistoryEntry> = listOf(
    HistoryEntry(trackId = "preview-history-1", playedAt = 3L, track = previewTracks()[0]),
    HistoryEntry(trackId = "preview-history-2", playedAt = 2L, track = previewTracks()[1]),
    HistoryEntry(trackId = "preview-history-3", playedAt = 1L, track = previewTracks()[2]),
)
