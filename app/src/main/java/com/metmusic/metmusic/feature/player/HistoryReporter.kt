package com.metmusic.metmusic.feature.player

import android.util.Log
import androidx.media3.common.MediaItem
import com.metmusic.metmusic.core.data.HistoryRepository
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private const val TAG = "HistoryReporter"
private const val MIN_PLAYED_MS = 3_000L
private const val COMPLETED_MARGIN_MS = 2_000L
private const val EXTRAS_TRACK_JSON = "trackJson"

/**
 * Registra en el historial cada pista que sonó lo suficiente.
 *
 * Espejo del comportamiento de Flutter: una pista se registra si sonó al
 * menos 3 s, y queda `completed` si llegó a 2 s del final. El reporte sale al
 * detectar el cambio de pista, con la última posición observada por
 * [PlayerConnection] mediante [onPositionTick].
 */
@Singleton
class HistoryReporter @Inject constructor(
    private val historyRepository: HistoryRepository,
    private val queueManager: QueueManager,
) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var previousTrack: Track? = null
    private var previousPlayedMs: Long = 0L
    private var previousDurationMs: Long = 0L

    /**
     * Cambió el ítem actual: reporta el anterior (si sonó lo suficiente) y
     * toma el nuevo como candidato para el próximo reporte. [reason] es el
     * motivo del cambio (auto-avance, salto manual, etc.).
     */
    fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
        reportAndReset(mediaItem)
    }

    /**
     * Última posición conocida de la pista actual. [PlayerConnection] la
     * llama en su tick de 500 ms con la reproducción activa y al pausar.
     */
    fun onPositionTick(positionMs: Long, durationMs: Long) {
        previousPlayedMs = positionMs
        previousDurationMs = durationMs
    }

    private fun reportAndReset(newItem: MediaItem?) {
        val previous = previousTrack
        val played = previousPlayedMs
        val duration = previousDurationMs
        if (previous != null && played >= MIN_PLAYED_MS) {
            val completed = duration > 0 && played >= duration - COMPLETED_MARGIN_MS
            val snapshot = previous
            scope.launch {
                try {
                    historyRepository.record(
                        trackId = snapshot.trackId,
                        playedMs = played,
                        completed = completed,
                        track = snapshot,
                    )
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.d(TAG, "history record failed: ${e.message}")
                }
            }
        }
        previousTrack = trackFor(newItem)
        previousPlayedMs = 0L
        previousDurationMs = 0L
    }

    /** Resuelve la pista del ítem nuevo: primero la cola, luego sus extras. */
    private fun trackFor(item: MediaItem?): Track? {
        if (item == null) return null
        queueManager.queue.value.firstOrNull { it.trackId == item.mediaId }?.let { return it }
        val json = item.extras?.getString(EXTRAS_TRACK_JSON) ?: return null
        return try {
            JsonParse.parse(json)?.let { Track.fromJson(it) }
        } catch (e: Exception) {
            null
        }
    }
}
