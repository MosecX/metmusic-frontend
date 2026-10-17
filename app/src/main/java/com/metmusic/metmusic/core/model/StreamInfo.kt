package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import java.time.LocalDateTime
import kotlin.math.roundToInt

/**
 * Resultado de `GET /api/stream/{trackId}`.
 *
 * El backend ya resolvió el proveedor (Qobuz/Tidal); la app solo reproduce.
 */
data class StreamInfo(
    val url: String,
    val trackId: String,
    val provider: String? = null,
    val quality: String? = null,
    val codec: String? = null,
    val bitrate: Int? = null,
    val sampleRate: Int? = null,
    val bitDepth: Int? = null,
    val expiresIn: Int? = null,
    val title: String? = null,
    val artist: String? = null,
    val album: String? = null,
    val thumbnail: String? = null,
    val durationSeconds: Int? = null,
    val isrc: String? = null,

    /** `direct` (progresivo) o `dash` (manifiesto DASH). */
    val manifestType: String = "direct",
    val isPreview: Boolean = false,

    /** Momento en que se obtuvo la URL (para detectar expiración). */
    val fetchedAt: LocalDateTime? = null,
) {
    val isDash: Boolean
        get() = manifestType.lowercase() == "dash"

    val isDirect: Boolean
        get() = !isDash

    /** True si la URL ya expiró o está por expirar (margen de 30 s). */
    val isExpired: Boolean
        get() {
            val expires = expiresIn ?: return false
            val fetched = fetchedAt ?: return false
            return LocalDateTime.now().isAfter(
                fetched.plusSeconds(expires.toLong()).minusSeconds(30),
            )
        }

    /** Etiqueta legible de calidad, ej. `FLAC 24/96` o `AAC 320 kbps`. */
    val qualityLabel: String
        get() {
            val parts = mutableListOf<String>()
            val codecLabel = codec?.uppercase().orEmpty()
            if (codecLabel.isNotEmpty()) parts.add(codecLabel)
            val bits = bitDepth
            val rate = sampleRate
            val kbps = bitrate
            if (bits != null && rate != null) {
                parts.add("$bits/${(rate / 1000.0).roundToInt()}")
            } else if (kbps != null) {
                parts.add("${(kbps / 1000.0).roundToInt()} kbps")
            }
            if (parts.isEmpty() && quality != null) return quality
            return if (parts.isEmpty()) "Auto" else parts.joinToString(" ")
        }

    companion object {
        fun fromJson(json: Map<String, Any?>): StreamInfo = StreamInfo(
            url = JsonParse.strOr(json["url"], ""),
            trackId = JsonParse.strOr(json["track_id"], ""),
            provider = JsonParse.str(json["provider"]),
            quality = JsonParse.str(json["quality"]),
            codec = JsonParse.str(json["codec"]),
            bitrate = JsonParse.asInt(json["bitrate"]),
            sampleRate = JsonParse.asInt(json["sample_rate"]),
            bitDepth = JsonParse.asInt(json["bit_depth"]),
            expiresIn = JsonParse.asInt(json["expires_in"]),
            title = JsonParse.str(json["title"]),
            artist = JsonParse.str(json["artist"]),
            album = JsonParse.str(json["album"]),
            thumbnail = JsonParse.str(json["thumbnail"]),
            durationSeconds = JsonParse.asInt(json["duration_seconds"]),
            isrc = JsonParse.str(json["isrc"]),
            manifestType = JsonParse.strOr(json["manifest_type"], "direct"),
            isPreview = JsonParse.boolOr(json["is_preview"], false),
            fetchedAt = LocalDateTime.now(),
        )
    }
}
