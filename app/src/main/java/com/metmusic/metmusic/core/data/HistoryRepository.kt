package com.metmusic.metmusic.core.data

import android.util.Log
import com.metmusic.metmusic.core.data.local.dao.HistoryDao
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import com.metmusic.metmusic.core.model.HistoryEntry
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "HistoryRepository"
private const val MAX_HISTORY_ENTRIES = 500
private const val REMOTE_SYNC_LIMIT = 100

/**
 * Historial local-first: Room es la fuente de verdad y el backend un espejo
 * silencioso (un fallo de red nunca revierte lo local).
 */
@Singleton
class HistoryRepository @Inject constructor(
    private val dao: HistoryDao,
    private val userRepository: UserRepository,
) {
    /** Registra una reproducción local y la espeja al backend sin bloquear. */
    suspend fun record(trackId: String, playedMs: Long, completed: Boolean, track: Track?) {
        dao.insert(
            HistoryEntity(
                trackId = trackId,
                playedAt = System.currentTimeMillis(),
                playedMs = playedMs,
                completed = completed,
                trackJson = track?.let { JsonParse.encode(it.toJson()) },
            ),
        )
        dao.trimTo(MAX_HISTORY_ENTRIES)
        try {
            userRepository.addHistory(trackId, playedMs, completed)
        } catch (e: ApiException) {
            Log.d(TAG, "Espejo de historial falló: ${e.message}")
        }
    }

    /** Entradas más recientes primero, con tope explícito. */
    suspend fun getAll(limit: Int): List<HistoryEntry> =
        dao.getAll(limit).map { it.toHistoryEntry() }

    /**
     * Los últimos [limit] tracks sin repetir, más nuevos primero (espejo del
     * `recentDistinct` de Flutter: escanea todo el historial ordenado).
     */
    suspend fun recentDistinct(limit: Int): List<HistoryEntry> {
        val seen = HashSet<String>()
        val result = mutableListOf<HistoryEntry>()
        for (entity in dao.getAllNoLimit()) {
            if (!seen.add(entity.trackId)) continue
            result += entity.toHistoryEntry()
            if (result.size >= limit) break
        }
        return result
    }

    suspend fun clear() {
        dao.clear()
        try {
            userRepository.clearHistory()
        } catch (e: ApiException) {
            Log.d(TAG, "Borrado del historial remoto falló: ${e.message}")
        }
    }

    /**
     * Fusiona el historial remoto con el local sin duplicar por
     * (trackId, playedAt) y sin pisar lo local.
     */
    suspend fun syncFromBackend() {
        val remote = try {
            userRepository.getHistory(limit = REMOTE_SYNC_LIMIT)
        } catch (e: ApiException) {
            Log.d(TAG, "Sync de historial falló: ${e.message}")
            return
        }
        val seen = dao.getAllNoLimit().mapTo(mutableSetOf()) { it.trackId to it.playedAt }
        for (entry in remote) {
            if (!seen.add(entry.trackId to entry.playedAt)) continue
            dao.insert(
                HistoryEntity(
                    trackId = entry.trackId,
                    playedAt = entry.playedAt,
                    playedMs = entry.playedMs.toLong(),
                    completed = entry.completed,
                    trackJson = entry.track?.let { JsonParse.encode(it.toJson()) },
                ),
            )
        }
        dao.trimTo(MAX_HISTORY_ENTRIES)
    }
}

/** Convierte la fila local al modelo, tolerando JSON corrupto. */
private fun HistoryEntity.toHistoryEntry(): HistoryEntry = HistoryEntry(
    trackId = trackId,
    playedAt = playedAt,
    playedMs = playedMs.toInt(),
    completed = completed,
    track = trackJson?.let { raw -> JsonParse.parse(raw)?.let { Track.fromJson(it) } },
)
