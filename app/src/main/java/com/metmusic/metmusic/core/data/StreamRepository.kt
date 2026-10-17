package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.StreamInfo
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.ParseApiException
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

/**
 * `GET /api/stream/{trackId}` — el endpoint central de reproducción.
 *
 * Cada llamada resuelve una URL nueva (Qobuz o Tidal) de un solo uso: el
 * [RetryInterceptor] nunca reintenta `/stream`.
 */
@Singleton
class StreamRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getStream(trackId: String, quality: AudioQualityPreference?): StreamInfo {
        val body = apiCall {
            api.stream(ApiEndpoints.stream(trackId), quality?.value)
        }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        val info = StreamInfo.fromJson(json)
        if (info.url.isEmpty()) {
            throw ParseApiException("El backend no devolvió una URL reproducible")
        }
        return info
    }
}
