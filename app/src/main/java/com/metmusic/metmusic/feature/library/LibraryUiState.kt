package com.metmusic.metmusic.feature.library

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.HistoryEntry
import com.metmusic.metmusic.core.model.RadioMix
import com.metmusic.metmusic.core.model.SavedMix
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist

/** Pestañas de la Biblioteca. */
enum class LibraryTab(val label: String) {
    PLAYLISTS("Playlists"),
    FAVORITES("Favoritos"),
    MIXES("Mixes"),
    HISTORY("Historial"),
}

/**
 * Snapshot inmutable de la Biblioteca.
 *
 * [error] es un fallo de carga (bloquea el contenido con reintento);
 * [actionError] es el fallo puntual de crear/renombrar/borrar y se muestra
 * como snackbar temporal.
 */
@Immutable
data class LibraryUiState(
    val selectedTab: LibraryTab = LibraryTab.PLAYLISTS,
    val isLoading: Boolean = true,
    val isRefreshing: Boolean = false,
    val error: String? = null,
    val playlists: List<UserPlaylist> = emptyList(),
    val favorites: List<Track> = emptyList(),
    val mixes: List<SavedMix> = emptyList(),
    val history: List<HistoryEntry> = emptyList(),
    val actionError: String? = null,
) {
    companion object {
        /** Estado de muestra con las cuatro listas cargadas (previews). */
        fun preview(tab: LibraryTab = LibraryTab.PLAYLISTS): LibraryUiState = LibraryUiState(
            selectedTab = tab,
            isLoading = false,
            playlists = previewPlaylists,
            favorites = previewTracks,
            mixes = previewMixes,
            history = previewHistory(),
        )
    }
}

private val previewTracks: List<Track> = listOf(
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

private val previewPlaylists: List<UserPlaylist> = listOf(
    UserPlaylist(playlistId = "preview-playlist-1", name = "Roadtrip", numberOfTracks = 24),
    UserPlaylist(
        playlistId = "preview-playlist-2",
        name = "Foco profundo",
        description = "Para estudiar",
        numberOfTracks = 12,
    ),
    UserPlaylist(playlistId = "preview-playlist-3", name = "Clásicos", numberOfTracks = 40),
)

private fun previewMixes(): List<SavedMix> = listOf(
    SavedMix(
        trackId = "preview-track-1",
        mix = RadioMix(id = "preview-mix-1", title = "Daft Punk Radio", subTitle = "Daft Punk"),
    ),
    SavedMix(
        trackId = "preview-track-2",
        mix = RadioMix(id = "preview-mix-2", title = "French Touch", description = "Nostalgia disco"),
    ),
)

private fun previewHistory(): List<HistoryEntry> {
    val now = System.currentTimeMillis()
    return listOf(
        HistoryEntry(
            trackId = "preview-track-1",
            playedAt = now - 5 * 60_000L,
            playedMs = 320_000,
            completed = true,
            track = previewTracks[0],
        ),
        HistoryEntry(
            trackId = "preview-track-2",
            playedAt = now - 3 * 60 * 60_000L,
            playedMs = 180_000,
            completed = true,
            track = previewTracks[1],
        ),
        HistoryEntry(
            trackId = "preview-track-3",
            playedAt = now - 2 * 24 * 60 * 60_000L,
            playedMs = 120_000,
            completed = false,
            track = previewTracks[2],
        ),
    )
}
