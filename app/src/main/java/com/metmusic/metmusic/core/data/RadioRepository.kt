package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.RadioStation
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.NotFoundApiException
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Radio contra `GET /api/tracks/{trackId}/radio`: un 404 significa "sin
 * estación" y una estación sin items también es `null`.
 */
@Singleton
class RadioRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getRadio(trackId: String): RadioStation? {
        val json = try {
            val body = apiCall { api.radio(ApiEndpoints.radio(trackId)) }.string()
            JsonParse.parse(body) ?: emptyMap()
        } catch (_: NotFoundApiException) {
            return null
        }
        val station = RadioStation.fromJson(json)
        return station.takeIf { it.items.isNotEmpty() }
    }
}
