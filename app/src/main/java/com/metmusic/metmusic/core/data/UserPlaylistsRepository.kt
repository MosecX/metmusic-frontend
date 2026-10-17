package com.metmusic.metmusic.core.data

import android.util.Log
import com.metmusic.metmusic.core.data.local.dao.UserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

private const val TAG = "UserPlaylistsRepository"

/**
 * Playlists propias: el backend es la fuente de verdad y el cache Room solo
 * acelera la lectura offline. Los errores del backend propagan como
 * [ApiException] para que la UI decida (a diferencia de favoritos/historial,
 * que son offline-first porque los produce el usuario).
 *
 * Nota de cache: en rename/addTracks/removeTrack/reorder el refetch es
 * best-effort: si falla, el error propaga igual y el cache queda
 * desactualizado hasta el próximo [refresh].
 */
@Singleton
class UserPlaylistsRepository @Inject constructor(
    private val dao: UserPlaylistDao,
    private val userRepository: UserRepository,
) {
    /** Cache local, sin tocar la red. La UI decide cuándo refrescar. */
    suspend fun getAll(): List<UserPlaylist> = dao.getAll().map { it.toUserPlaylist() }

    /** Trae la lista completa del backend y reemplaza el cache. */
    suspend fun refresh() {
        val playlists = try {
            userRepository.getPlaylists()
        } catch (e: ApiException) {
            Log.d(TAG, "Refresh de playlists falló: ${e.message}")
            throw e
        }
        dao.replaceAll(playlists.map { it.toEntity() })
    }

    suspend fun create(name: String, description: String?, coverUrl: String?): UserPlaylist {
        val created = userRepository.createPlaylist(name, description, coverUrl)
        dao.insert(created.toEntity())
        return created
    }

    suspend fun rename(id: String, name: String): UserPlaylist {
        val updated = userRepository.updatePlaylist(id, name = name)
        dao.insert(updated.toEntity())
        return updated
    }

    suspend fun delete(id: String) {
        userRepository.deletePlaylist(id)
        dao.deleteById(id)
    }

    suspend fun addTracks(id: String, trackIds: List<String>) {
        userRepository.addTracks(id, trackIds)
        cacheRefetched(id)
    }

    suspend fun removeTrack(id: String, trackId: String) {
        userRepository.removeTrack(id, trackId)
        cacheRefetched(id)
    }

    suspend fun reorder(id: String, orderedTrackIds: List<String>) {
        userRepository.reorder(id, orderedTrackIds)
        cacheRefetched(id)
    }

    /** Refetch best-effort del playlist completo para actualizar el cache. */
    private suspend fun cacheRefetched(id: String) {
        dao.insert(userRepository.getPlaylist(id).toEntity())
    }
}

/** Fila Room → modelo. `tracksJson` inválido o ausente cae a lista vacía. */
private fun UserPlaylistEntity.toUserPlaylist(): UserPlaylist = UserPlaylist(
    playlistId = id,
    name = name,
    description = description,
    coverUrl = coverUrl,
    numberOfTracks = trackCount,
    tracks = decodeTracks(tracksJson),
    createdAt = createdAt,
    updatedAt = updatedAt,
)

/** Modelo → fila Room (cache). */
private fun UserPlaylist.toEntity(): UserPlaylistEntity = UserPlaylistEntity(
    id = playlistId,
    name = name,
    description = description,
    coverUrl = coverUrl,
    trackCount = numberOfTracks,
    tracksJson = tracks.toTracksJson(),
    createdAt = createdAt,
    updatedAt = updatedAt,
    cachedAt = System.currentTimeMillis(),
)

/** Serializa los tracks como array JSON para la columna `tracksJson`. */
private fun List<Track>.toTracksJson(): String = JsonParse.encode(map { it.toJson() })

/** Parsea el array JSON de tracks; cualquier forma inesperada da emptyList. */
private fun decodeTracks(raw: String): List<Track> {
    val trimmed = raw.trim()
    if (trimmed.isEmpty() || !trimmed.startsWith("[")) return emptyList()
    val json = JsonParse.parse("""{"items":$trimmed}""") ?: return emptyList()
    return JsonParse.maps(json["items"]).map { Track.fromJson(it) }
}
