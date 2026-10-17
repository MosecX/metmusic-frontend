package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/**
 * Resultado de `GET /api/canvas/{trackId}`.
 *
 * Si el backend responde 404, no hay canvas y se muestra artwork estático.
 */
data class CanvasMedia(
    val url: String,
    val provider: String? = null,
    /** `hls` (playlist) o `mp4` (vídeo directo). */
    val kind: String = "mp4",
    val urlTall: String? = null,
) {
    val isHls: Boolean
        get() = kind.equals("hls", ignoreCase = true)

    val isMp4: Boolean
        get() = !isHls

    /**
     * URL efectiva a reproducir.
     *
     * Los canvases de Apple Music vienen en vertical: se usa [urlTall] cuando
     * existe y se cae a [url] si no. Spotify (y el resto) usan [url] tal cual.
     */
    val displayUrl: String
        get() {
            val tall = urlTall
            val isApple = provider?.lowercase()?.contains("apple") == true
            return if (isApple && !tall.isNullOrEmpty()) tall else url
        }

    companion object {
        fun fromJson(json: Map<String, Any?>): CanvasMedia = CanvasMedia(
            url = JsonParse.strOr(json["url"], ""),
            provider = JsonParse.str(json["provider"]),
            kind = JsonParse.strOr(json["kind"], "mp4"),
            urlTall = JsonParse.str(json["url_tall"]),
        )
    }
}
