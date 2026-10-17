package com.metmusic.metmusic.feature.album

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Track

/** Estado del detalle de álbum (6E-1): carga, álbum y error. */
@Immutable
data class AlbumDetailUiState(
    val isLoading: Boolean = true,
    val album: Album? = null,
    val error: String? = null,
) {
    companion object {
        /** Estado de muestra con álbum para previews. */
        fun preview(): AlbumDetailUiState = AlbumDetailUiState(
            isLoading = false,
            album = previewAlbum(),
        )

        /** Estado de muestra en error para previews. */
        fun previewError(): AlbumDetailUiState = AlbumDetailUiState(
            isLoading = false,
            error = "Sin conexión al servidor",
        )
    }
}

/** Álbum fake con 5 tracks para previews. */
private fun previewAlbum(): Album = Album(
    albumId = "preview-album",
    title = "Discovery",
    artist = "Daft Punk",
    artistId = "preview-artist",
    releaseDate = "2001-03-07",
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
            title = "Harder, Better, Faster, Stronger",
            artist = "Daft Punk",
            durationSeconds = 224,
        ),
        Track(
            trackId = "preview-track-5",
            title = "Veridis Quo",
            artist = "Daft Punk",
            durationSeconds = 344,
        ),
    ),
)
