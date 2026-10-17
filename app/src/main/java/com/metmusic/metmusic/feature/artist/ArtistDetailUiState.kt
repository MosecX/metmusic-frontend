package com.metmusic.metmusic.feature.artist

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.model.Track

/** Estado del detalle de artista (6E-1): carga, artista y error. */
@Immutable
data class ArtistDetailUiState(
    val isLoading: Boolean = true,
    val artist: Artist? = null,
    val error: String? = null,
) {
    companion object {
        /** Estado de muestra con artista para previews. */
        fun preview(): ArtistDetailUiState = ArtistDetailUiState(
            isLoading = false,
            artist = previewArtist(),
        )

        /** Estado de muestra en error para previews. */
        fun previewError(): ArtistDetailUiState = ArtistDetailUiState(
            isLoading = false,
            error = "Sin conexión al servidor",
        )
    }
}

/** Artista fake con top tracks y discografía para previews. */
private fun previewArtist(): Artist = Artist(
    artistId = "preview-artist",
    name = "Daft Punk",
    bio = "Dúo francés de música electrónica formado en París en 1993. " +
        "Referentes del french house con una carrera de casi tres décadas.",
    topTracks = listOf(
        Track(
            trackId = "preview-track-1",
            title = "One More Time",
            artist = "Daft Punk",
            durationSeconds = 320,
        ),
        Track(
            trackId = "preview-track-2",
            title = "Instant Crush",
            artist = "Daft Punk",
            durationSeconds = 337,
        ),
        Track(
            trackId = "preview-track-3",
            title = "Get Lucky",
            artist = "Daft Punk",
            durationSeconds = 369,
        ),
        Track(
            trackId = "preview-track-4",
            title = "Digital Love",
            artist = "Daft Punk",
            durationSeconds = 301,
        ),
        Track(
            trackId = "preview-track-5",
            title = "Veridis Quo",
            artist = "Daft Punk",
            durationSeconds = 344,
        ),
    ),
    albums = listOf(
        Album(albumId = "preview-album-1", title = "Discovery", artist = "Daft Punk"),
        Album(albumId = "preview-album-2", title = "Random Access Memories", artist = "Daft Punk"),
        Album(albumId = "preview-album-3", title = "Homework", artist = "Daft Punk"),
    ),
)
