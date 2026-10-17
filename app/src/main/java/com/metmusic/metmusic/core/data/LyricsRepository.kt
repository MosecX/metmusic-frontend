package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Lyrics
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.NotFoundApiException
import com.metmusic.metmusic.core.network.ServerApiException
import com.metmusic.metmusic.core.network.UnauthorizedApiException
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.delay

private const val TOO_MANY_REQUESTS = 429
private const val RETRY_BACKOFF_MS = 800L

/**
 * Letras contra `GET /api/lyrics/{trackId}`.
 *
 * Contrato con el backend:
 * - 404 (sin letras) y 401 (token) devuelven `null`, sin reintentos en bucle.
 * - 429: un reintento con backoff; si vuelve a fallar, `null`.
 * - 5xx y el resto: `null` (la UI cae al fallback local).
 */
@Singleton
class LyricsRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getLyrics(trackId: String): Lyrics? = try {
        fetch(trackId)
    } catch (_: NotFoundApiException) {
        null
    } catch (_: UnauthorizedApiException) {
        null
    } catch (error: ServerApiException) {
        if (error.statusCode != TOO_MANY_REQUESTS) {
            null
        } else {
            delay(RETRY_BACKOFF_MS)
            try {
                fetch(trackId)
            } catch (_: ApiException) {
                null
            }
        }
    } catch (_: ApiException) {
        null
    }

    private suspend fun fetch(trackId: String): Lyrics? {
        val body = apiCall { api.lyrics(ApiEndpoints.lyrics(trackId)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        val map = (json["lyrics"] as? Map<*, *>)?.stringKeyed() ?: json
        val lyrics = Lyrics.fromJson(map)
        return lyrics.takeIf { it.hasLyrics }
    }
}
