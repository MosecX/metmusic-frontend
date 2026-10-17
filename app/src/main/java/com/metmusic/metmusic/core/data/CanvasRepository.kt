package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.CanvasMedia
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.NotFoundApiException
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Canvas contra `GET /api/canvas/{trackId}`: un 404 significa "sin canvas" y
 * se devuelve `null` (artwork estático); una url vacía también es `null`.
 */
@Singleton
class CanvasRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getCanvas(trackId: String): CanvasMedia? {
        val json = try {
            val body = apiCall { api.canvas(ApiEndpoints.canvas(trackId)) }.string()
            JsonParse.parse(body) ?: emptyMap()
        } catch (_: NotFoundApiException) {
            return null
        }
        val map = (json["canvas"] as? Map<*, *>)?.stringKeyed() ?: json
        val media = CanvasMedia.fromJson(map)
        return media.takeIf { it.url.isNotEmpty() }
    }
}
