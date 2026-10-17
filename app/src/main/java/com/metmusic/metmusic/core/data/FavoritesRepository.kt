package com.metmusic.metmusic.core.data

import android.util.Log
import com.metmusic.metmusic.core.data.local.dao.FavoritesDao
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "FavoritesRepository"
private const val REMOTE_SYNC_LIMIT = 200

/**
 * Favoritos local-first: Room es la fuente de verdad y el backend un espejo
 * silencioso (un fallo de red nunca revierte lo local).
 */
@Singleton
class FavoritesRepository @Inject constructor(
    private val dao: FavoritesDao,
    private val userRepository: UserRepository,
) {
    suspend fun isFavorite(trackId: String): Boolean = dao.exists(trackId)

    /** Favoritos locales, más nuevos primero; las filas corruptas se descartan. */
    suspend fun getAll(): List<Track> = dao.getAll().mapNotNull { decodeTrack(it.trackJson) }

    /** Alterna el estado local y devuelve el nuevo valor (true = favorito). */
    suspend fun toggle(track: Track): Boolean {
        if (dao.exists(track.trackId)) {
            dao.deleteByTrackId(track.trackId)
            mirrorRemoval(track.trackId)
            return false
        }
        dao.insert(
            FavoritesEntity(
                trackId = track.trackId,
                trackJson = JsonParse.encode(track.toJson()),
                addedAt = System.currentTimeMillis(),
            ),
        )
        try {
            userRepository.addFavorite(track.trackId)
        } catch (e: ApiException) {
            Log.d(TAG, "Alta de favorito remota falló: ${e.message}")
        }
        return true
    }

    suspend fun remove(trackId: String) {
        dao.deleteByTrackId(trackId)
        mirrorRemoval(trackId)
    }

    /** Reemplaza el caché local con la lista del backend (gana el servidor). */
    suspend fun syncFromBackend() {
        val remote = try {
            userRepository.getFavorites(limit = REMOTE_SYNC_LIMIT)
        } catch (e: ApiException) {
            Log.d(TAG, "Sync de favoritos falló: ${e.message}")
            return
        }
        val now = System.currentTimeMillis()
        dao.clear()
        for ((index, track) in remote.withIndex()) {
            dao.insert(
                FavoritesEntity(
                    trackId = track.trackId,
                    trackJson = JsonParse.encode(track.toJson()),
                    // now - index: la consulta DESC conserva el orden del backend.
                    addedAt = now - index,
                ),
            )
        }
    }

    private suspend fun mirrorRemoval(trackId: String) {
        try {
            userRepository.removeFavorite(trackId)
        } catch (e: ApiException) {
            Log.d(TAG, "Baja de favorito remota falló: ${e.message}")
        }
    }
}

/** Decodifica el track de una fila; null cuando el JSON está corrupto. */
private fun decodeTrack(raw: String): Track? = JsonParse.parse(raw)?.let { Track.fromJson(it) }
