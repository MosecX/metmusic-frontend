package com.metmusic.metmusic.feature.playlist

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.model.Track

/** Estado del detalle de playlist editorial (6E-1): carga, playlist y error. */
@Immutable
data class PlaylistDetailUiState(
    val isLoading: Boolean = true,
    val playlist: Playlist? = null,
    val error: String? = null,
) {
    companion object {
        /** Estado de muestra con playlist para previews. */
        fun preview(): PlaylistDetailUiState = PlaylistDetailUiState(
            isLoading = false,
            playlist = previewPlaylist(),
        )

        /** Estado de muestra en error para previews. */
        fun previewError(): PlaylistDetailUiState = PlaylistDetailUiState(
            isLoading = false,
            error = "Sin conexión al servidor",
        )
    }
}

/** Playlist fake con 5 tracks para previews. */
private fun previewPlaylist(): Playlist = Playlist(
    playlistId = "preview-playlist",
    title = "French Touch Classics",
    creator = "MetMusic",
    description = "Una selección de clásicos del french touch para arrancar la noche.",
    numberOfTracks = 5,
    tracks = listOf(
        Track(
            trackId = "preview-track-1",
            title = "One More Time",
            artist = "Daft Punk",
            durationSeconds = 320,
        ),
        Track(
            trackId = "preview-track-2",
            title = "Aerodynamic",
            artist = "Daft Punk",
            durationSeconds = 212,
        ),
        Track(
            trackId = "preview-track-3",
            title = "Digital Love",
            artist = "Daft Punk",
            durationSeconds = 301,
        ),
        Track(
            trackId = "preview-track-4",
            title = "Music Sounds Better with You",
            artist = "Stardust",
            durationSeconds = 261,
        ),
        Track(
            trackId = "preview-track-5",
            title = "Lady (Hear Me Tonight)",
            artist = "Modjo",
            durationSeconds = 302,
        ),
    ),
)
