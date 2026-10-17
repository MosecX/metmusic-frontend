package com.metmusic.metmusic.feature.mix

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.RadioStation
import com.metmusic.metmusic.core.model.Track

/**
 * Estado de [MixScreen] (pantalla de estación radial). La URL de error de red
 * es un fallo de comunicación; [isNotFound] es el 404 del backend ("esta pista
 * no tiene estación"). Las dos no se pueden mezclar.
 */
@Immutable
data class MixUiState(
    val isLoading: Boolean = true,
    val isNotFound: Boolean = false,
    val station: RadioStation? = null,
    val isFavorite: Boolean = false,
    val isTogglingFavorite: Boolean = false,
    val error: String? = null,
    val actionError: String? = null,
) {
    val tracks: List<Track> get() = station?.items ?: emptyList()
    val title: String get() = station?.mix?.title ?: ""
    val subTitle: String? get() = station?.mix?.subTitle
    val description: String? get() = station?.mix?.description
    val imageUrl: String? get() = station?.mix?.imageUrl

    companion object {
        fun preview(): MixUiState = MixUiState(
            isLoading = false,
            station = previewStation(),
            isFavorite = true,
        )

        fun previewNotFound(): MixUiState = MixUiState(
            isLoading = false,
            isNotFound = true,
        )

        fun previewError(): MixUiState = MixUiState(
            isLoading = false,
            error = "Sin conexión al servidor",
        )

        fun previewLoading(): MixUiState = MixUiState(isLoading = true)
    }
}

private fun previewStation(): RadioStation = RadioStation(
    trackId = "preview-seed",
    mix = RadioMix(
        id = "preview-mix",
        title = "Daft Punk Radio",
        subTitle = "Daft Punk",
        description = "Estación familiar con las canciones más legendarias de la discográfica.",
        imageUrl = "https://example.com/preview-mix.jpg",
    ),
    items = listOf(
        Track(
            trackId = "preview-1",
            title = "One More Time",
            artist = "Daft Punk",
            album = "Discovery",
            durationSeconds = 320,
            thumbnails = emptyList(),
        ),
        Track(
            trackId = "preview-2",
            title = "Instant Crush",
            artist = "Daft Punk",
            album = "Random Access Memories",
            durationSeconds = 337,
            thumbnails = emptyList(),
        ),
        Track(
            trackId = "preview-3",
            title = "Get Lucky",
            artist = "Daft Punk",
            album = "Get Lucky",
            durationSeconds = 252,
            thumbnails = emptyList(),
        ),
        Track(
            trackId = "preview-4",
            title = "Harder Better Faster Stronger",
            artist = "Daft Punk",
            album = "Doin' It Right",
            durationSeconds = 221,
            thumbnails = emptyList(),
        ),
        Track(
            trackId = "preview-5",
            title = "Digital Love",
            artist = "Daft Punk",
            album = "Discovery",
            durationSeconds = 332,
            thumbnails = emptyList(),
        ),
    ),
)
