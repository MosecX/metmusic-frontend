package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.model.ExploreHome
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

/** Exploración de la Home contra `/api/explore/...`. */
@Singleton
class ExploreRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getHome(mood: String?): ExploreHome {
        val body = apiCall { api.exploreHome(ApiEndpoints.EXPLORE_HOME, mood) }.string()
        return ExploreHome.fromJson(JsonParse.parse(body))
    }

    suspend fun getNewReleases(limit: Int = 20, offset: Int = 0): List<Album> {
        val body = apiCall {
            api.exploreNewReleases(ApiEndpoints.EXPLORE_NEW_RELEASES, limit, offset)
        }.string()
        val json = parseObjectBody(body)
        val value = json["albums"]
            ?: json["items"]
            ?: json["results"]
            ?: json["new_releases"]
            ?: json["data"]
        return JsonParse.maps(value).map { Album.fromJson(it) }
    }

    suspend fun getCharts(limit: Int = 20): List<Track> {
        val body = apiCall { api.exploreCharts(ApiEndpoints.EXPLORE_CHARTS, limit) }.string()
        return tracksFrom(parseObjectBody(body))
    }

    suspend fun getMood(mood: String, limit: Int = 30): List<Track> {
        val body = apiCall { api.exploreMoods(ApiEndpoints.EXPLORE_MOODS, mood, limit) }.string()
        return tracksFrom(parseObjectBody(body))
    }
}

/** Mismo orden de claves que el servicio Flutter para listas de tracks. */
private fun tracksFrom(json: Map<String, Any?>): List<Track> {
    val value = json["tracks"]
        ?: json["items"]
        ?: json["results"]
        ?: json["charts"]
        ?: json["data"]
    return JsonParse.maps(value).map { Track.fromJson(it) }
}

/**
 * Parsea el cuerpo como objeto; si la raíz es un array JSON se envuelve en
 * un objeto con la clave `items` para reusar el parser de [JsonParse].
 */
private fun parseObjectBody(raw: String): Map<String, Any?> {
    val trimmed = raw.trim()
    val candidate = if (trimmed.startsWith("[")) """{"items":$trimmed}""" else trimmed
    return JsonParse.parse(candidate) ?: emptyMap()
}
