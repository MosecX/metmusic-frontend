package com.metmusic.metmusic.feature.player

import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.StreamInfo
import com.metmusic.metmusic.core.model.Track
import java.time.Duration

/**
 * Snapshot inmutable del reproductor para la UI.
 *
 * [PlayerConnection] lo publica a partir de los eventos del `MediaController`
 * de Media3; la UI nunca toca Media3 directamente.
 */
data class PlayerUiState(
    val mediaId: String? = null,
    val track: Track? = null,
    val isPlaying: Boolean = false,
    val isBuffering: Boolean = false,
    val processingState: ProcessingState = ProcessingState.IDLE,
    val position: Duration = Duration.ZERO,
    val duration: Duration = Duration.ZERO,
    val buffered: Duration = Duration.ZERO,
    val queue: List<Track> = emptyList(),
    val currentIndex: Int = -1,
    val shuffleEnabled: Boolean = false,
    val repeatMode: RepeatMode = RepeatMode.OFF,
    val streamInfo: StreamInfo? = null,
    val error: String? = null,
) {
    /** Estado del pipeline de reproducción del controller. */
    enum class ProcessingState {
        IDLE,
        LOADING,
        BUFFERING,
        READY,
        ENDED,
        ERROR,
    }

    /** Hay una pista cargada en el player. */
    val hasTrack: Boolean get() = track != null

    /** Título visible de la pista actual (`""` si no hay). */
    val title: String get() = track?.displayTitle ?: ""

    /** Artista de la pista actual (`""` si no hay). */
    val artist: String get() = track?.artist ?: ""

    /** Álbum de la pista actual (`""` si no hay). */
    val album: String get() = track?.album ?: ""

    /** Artwork: prioriza la miniatura del stream resuelto sobre la del track. */
    val artworkUrl: String get() = streamInfo?.thumbnail ?: track?.thumbnailUrl ?: ""

    /** Progreso 0..1; `0f` cuando la duración es desconocida. */
    val progress: Float
        get() {
            val total = duration.toMillis()
            if (total <= 0L) return 0f
            return (position.toMillis().toFloat() / total.toFloat()).coerceIn(0f, 1f)
        }

    /** Hay una pista después de la actual. */
    val hasNext: Boolean get() = currentIndex >= 0 && currentIndex < queue.lastIndex

    /** Hay una pista antes de la actual. */
    val hasPrevious: Boolean get() = currentIndex > 0

    companion object {
        /** Estado inicial: sin pista ni cola. */
        val EMPTY = PlayerUiState()
    }
}
