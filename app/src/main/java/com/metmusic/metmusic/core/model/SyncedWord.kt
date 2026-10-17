package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/** Una palabra de una línea con sincronía a nivel de palabra. */
data class SyncedWord(
    val timeMs: Long,
    val text: String,
    val durationMs: Long? = null,
) {
    fun toJson(): Map<String, Any?> = buildMap {
        put("time_ms", timeMs)
        durationMs?.let { put("duration_ms", it) }
        put("text", text)
    }

    companion object {
        fun fromJson(json: Map<String, Any?>): SyncedWord = SyncedWord(
            timeMs = JsonParse.longOr(json["time_ms"], 0L),
            durationMs = JsonParse.asLong(json["duration_ms"]),
            text = JsonParse.strOr(json["text"], ""),
        )
    }
}
