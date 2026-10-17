package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.HistoryEntry
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.UserPlaylist
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.add
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody

/** Endpoints de usuario: playlists propias, historial y favoritos. */
@Singleton
class UserRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getPlaylists(): List<UserPlaylist> {
        val body = apiCall { api.userPlaylists(ApiEndpoints.USER_PLAYLISTS) }.string()
        val json = parseObjectBody(body)
        val value = json["playlists"] ?: json["items"] ?: json["results"] ?: json["data"]
        return JsonParse.maps(value).map { UserPlaylist.fromJson(it) }
    }

    suspend fun getPlaylist(id: String): UserPlaylist {
        val body = apiCall { api.userPlaylist(ApiEndpoints.userPlaylist(id)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        return UserPlaylist.fromJson((json["playlist"] as? Map<*, *>)?.stringKeyed() ?: json)
    }

    suspend fun createPlaylist(
        name: String,
        description: String?,
        coverUrl: String?,
    ): UserPlaylist {
        val body = buildJsonObject {
            put("name", name)
            description?.let { put("description", it) }
            coverUrl?.let { put("cover_url", it) }
        }.toJsonBody()
        val response = apiCall {
            api.createUserPlaylist(ApiEndpoints.USER_PLAYLISTS, body)
        }.string()
        return UserPlaylist.fromJson(JsonParse.parse(response) ?: emptyMap())
    }

    suspend fun updatePlaylist(
        id: String,
        name: String?,
        description: String?,
        coverUrl: String?,
    ): UserPlaylist {
        val body = buildJsonObject {
            name?.let { put("name", it) }
            description?.let { put("description", it) }
            coverUrl?.let { put("cover_url", it) }
        }.toJsonBody()
        val response = apiCall {
            api.updateUserPlaylist(ApiEndpoints.userPlaylist(id), body)
        }.string()
        val json = JsonParse.parse(response) ?: emptyMap()
        if (json.isEmpty()) {
            return UserPlaylist(playlistId = id, name = name ?: "", description = description)
        }
        return UserPlaylist.fromJson((json["playlist"] as? Map<*, *>)?.stringKeyed() ?: json)
    }

    suspend fun deletePlaylist(id: String) {
        apiCall { api.deleteUserPlaylist(ApiEndpoints.userPlaylist(id)) }.close()
    }

    suspend fun addTracks(id: String, trackIds: List<String>) {
        if (trackIds.isEmpty()) return
        val body = buildJsonArray { trackIds.forEach { add(it) } }.toJsonBody()
        apiCall { api.addTracksToPlaylist(ApiEndpoints.userPlaylistTracks(id), body) }.close()
    }

    suspend fun removeTrack(id: String, trackId: String) {
        apiCall {
            api.removeTrackFromPlaylist(ApiEndpoints.userPlaylistTrack(id, trackId))
        }.close()
    }

    suspend fun reorder(id: String, orderedTrackIds: List<String>) {
        val body = buildJsonArray { orderedTrackIds.forEach { add(it) } }.toJsonBody()
        apiCall { api.reorderPlaylist(ApiEndpoints.userPlaylistReorder(id), body) }.close()
    }

    suspend fun addHistory(trackId: String, playedMs: Long, completed: Boolean) {
        val body = buildJsonObject {
            put("track_id", trackId)
            put("played_ms", playedMs)
            put("completed", completed)
        }.toJsonBody()
        apiCall { api.addHistory(ApiEndpoints.USER_HISTORY, body) }.close()
    }

    suspend fun getHistory(limit: Int = 50, offset: Int = 0): List<HistoryEntry> {
        val body = apiCall {
            api.userHistory(ApiEndpoints.USER_HISTORY, limit, offset)
        }.string()
        val json = parseObjectBody(body)
        val value = json["history"] ?: json["items"] ?: json["results"] ?: json["data"]
        return JsonParse.maps(value).map { HistoryEntry.fromJson(it) }
    }

    suspend fun clearHistory() {
        apiCall { api.clearHistory(ApiEndpoints.USER_HISTORY) }.close()
    }

    suspend fun getFavorites(limit: Int = 200, offset: Int = 0): List<Track> {
        val body = apiCall {
            api.userFavorites(ApiEndpoints.USER_FAVORITES, limit, offset)
        }.string()
        val json = parseObjectBody(body)
        val value = json["favorites"]
            ?: json["tracks"]
            ?: json["items"]
            ?: json["results"]
            ?: json["data"]
        return JsonParse.maps(value).map { Track.fromJson(it) }
    }

    suspend fun addFavorite(trackId: String) {
        apiCall { api.addFavorite(ApiEndpoints.userFavorite(trackId)) }.close()
    }

    suspend fun removeFavorite(trackId: String) {
        apiCall { api.removeFavorite(ApiEndpoints.userFavorite(trackId)) }.close()
    }

    suspend fun checkFavorites(trackIds: List<String>): Set<String> {
        if (trackIds.isEmpty()) return emptySet()
        val body = apiCall {
            api.checkFavorites(ApiEndpoints.USER_FAVORITES_CHECK, trackIds.joinToString(","))
        }.string()
        val json = parseObjectBody(body)
        val value = json["favorites"] ?: json["ids"] ?: json["track_ids"] ?: json["items"]
        if (value is List<*>) return JsonParse.strings(value).toSet()
        if (json.values.all { it is Boolean }) {
            return json.filterValues { it == true }.keys
        }
        return emptySet()
    }
}

private val JSON_MEDIA_TYPE = "application/json".toMediaType()

private fun JsonElement.toJsonBody(): RequestBody =
    toString().toRequestBody(JSON_MEDIA_TYPE)

/**
 * Parsea el cuerpo como objeto; si la raíz es un array JSON se envuelve en
 * un objeto con la clave `items` para reusar el parser de [JsonParse].
 */
private fun parseObjectBody(raw: String): Map<String, Any?> {
    val trimmed = raw.trim()
    val candidate = if (trimmed.startsWith("[")) """{"items":$trimmed}""" else trimmed
    return JsonParse.parse(candidate) ?: emptyMap()
}
