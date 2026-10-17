package com.metmusic.metmusic.feature.userplaylist

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist

/**
 * Snapshot de una playlist propia (6E-2).
 *
 * [tracks] vive separado de `playlist.tracks` para poder aplicar el reorder y
 * el remove de forma optimista sin reconstruir el [UserPlaylist] completo en
 * cada interacción; [playlist] se conserva para la metadata (nombre,
 * descripción y cover).
 *
 * [error] es un fallo de carga (bloquea el contenido con reintento);
 * [actionError] es el fallo puntual de quitar/reordenar/agregar y se muestra
 * como snackbar temporal.
 */
@Immutable
data class UserPlaylistUiState(
    val isLoading: Boolean = true,
    val playlist: UserPlaylist? = null,
    val tracks: List<Track> = emptyList(),
    val isEditMode: Boolean = false,
    val error: String? = null,
    val actionError: String? = null,
    val isSavingOrder: Boolean = false,
) {
    companion object {
        /** Estado de muestra con la playlist cargada (previews). */
        fun preview(): UserPlaylistUiState = UserPlaylistUiState(
            isLoading = false,
            playlist = previewPlaylist(),
            tracks = previewTracks,
        )

        /** Estado de muestra con el modo edición activo (previews). */
        fun previewEdit(): UserPlaylistUiState = preview().copy(isEditMode = true)

        /** Estado de muestra de una playlist sin canciones (previews). */
        fun previewEmpty(): UserPlaylistUiState = UserPlaylistUiState(
            isLoading = false,
            playlist = previewPlaylist(trackCount = 0),
            tracks = emptyList(),
        )

        /** Estado de muestra de un fallo de carga (previews). */
        fun previewError(): UserPlaylistUiState = UserPlaylistUiState(
            isLoading = false,
            error = "Sin conexión al servidor",
        )
    }
}

private val previewTracks: List<Track> = listOf(
    Track(
        trackId = "preview-user-track-1",
        title = "One More Time",
        artist = "Daft Punk",
        album = "Discovery",
        durationSeconds = 320,
    ),
    Track(
        trackId = "preview-user-track-2",
        title = "Around the World",
        artist = "Daft Punk",
        album = "Homework",
        durationSeconds = 429,
    ),
    Track(
        trackId = "preview-user-track-3",
        title = "Instant Crush",
        artist = "Daft Punk",
        album = "Random Access Memories",
        durationSeconds = 337,
    ),
    Track(
        trackId = "preview-user-track-4",
        title = "Get Lucky",
        artist = "Daft Punk",
        album = "Random Access Memories",
        durationSeconds = 369,
    ),
)

private fun previewPlaylist(trackCount: Int = previewTracks.size): UserPlaylist = UserPlaylist(
    playlistId = "preview-user-playlist-1",
    name = "Roadtrip",
    description = "Para manejar de noche",
    numberOfTracks = trackCount,
    tracks = if (trackCount == 0) emptyList() else previewTracks,
)
