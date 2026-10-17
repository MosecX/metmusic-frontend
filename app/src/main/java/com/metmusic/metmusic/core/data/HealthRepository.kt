package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.HealthStatus
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

/** Salud del backend y mantenimiento: `GET /api/health` y `DELETE /api/cache`. */
@Singleton
class HealthRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun check(): HealthStatus {
        val body = apiCall { api.health() }.string()
        return HealthStatus.fromJson(JsonParse.parse(body) ?: emptyMap())
    }

    suspend fun clearServerCache() {
        apiCall { api.clearServerCache(ApiEndpoints.CACHE) }.close()
    }
}
