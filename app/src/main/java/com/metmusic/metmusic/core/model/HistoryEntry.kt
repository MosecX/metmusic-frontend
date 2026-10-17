package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import java.time.Instant
import java.time.LocalDateTime
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeParseException

/**
 * Entrada del historial de reproducción (local o remota).
 *
 * [playedAt] se normaliza a epoch en milisegundos: el backend puede mandar
 * fecha ISO, época en segundos o época en milisegundos.
 */
data class HistoryEntry(
    val trackId: String,
    val playedAt: Long,
    val playedMs: Int = 0,
    val completed: Boolean = false,
    /** Metadatos embebidos (el backend puede devolverlos o no). */
    val track: Track? = null,
) {
    /** Título a mostrar: el del track embebido o un fallback por id. */
    val title: String
        get() = track?.title ?: "Track $trackId"

    val artist: String
        get() = track?.artist ?: ""

    val thumbnailUrl: String
        get() = track?.thumbnailUrl ?: ""

    companion object {
        fun fromJson(json: Map<String, Any?>): HistoryEntry = HistoryEntry(
            trackId = JsonParse.strOr(json["track_id"] ?: json["id"], ""),
            playedAt = parseEpochMillis(
                json["played_at"] ?: json["created_at"] ?: json["timestamp"],
            ) ?: System.currentTimeMillis(),
            playedMs = JsonParse.intOr(json["played_ms"], 0),
            completed = JsonParse.boolOr(json["completed"], false),
            track = (json["track"] as? Map<*, *>)?.stringKeyed()?.let { Track.fromJson(it) }
                ?: if (json.containsKey("title")) Track.fromJson(json) else null,
        )

        /** Tolerante: acepta `[{...}]` y descarta items que no sean mapas. */
        fun listFrom(value: Any?): List<HistoryEntry> =
            JsonParse.maps(value).map { fromJson(it) }
    }
}

/** Convierte época (segundos o milisegundos) o fecha ISO-8601 a epoch millis. */
private fun parseEpochMillis(value: Any?): Long? {
    if (value == null) return null

    val numeric = JsonParse.asLong(value)
    if (numeric != null) {
        // Época en segundos o en milisegundos (mismo umbral que Flutter).
        return if (numeric > 100_000_000_000L) numeric else numeric * 1000L
    }

    val text = value.toString()
    return try {
        Instant.parse(text).toEpochMilli()
    } catch (_: DateTimeParseException) {
        try {
            OffsetDateTime.parse(text).toInstant().toEpochMilli()
        } catch (_: DateTimeParseException) {
            try {
                LocalDateTime.parse(text).toInstant(ZoneOffset.UTC).toEpochMilli()
            } catch (_: DateTimeParseException) {
                null
            }
        }
    }
}
