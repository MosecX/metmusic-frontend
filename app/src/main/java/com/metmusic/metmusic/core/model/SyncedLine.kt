package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/** Una línea de letra sincronizada. */
data class SyncedLine(
    val timeMs: Long,
    val text: String,
    /** Duración opcional: si es `null` la línea llega hasta la siguiente. */
    val durationMs: Long? = null,
    /** Palabras individuales; sólo viene con `sync_level: word`. */
    val words: List<SyncedWord> = emptyList(),
) {
    /**
     * Fin teórico de la línea (`time_ms + duration_ms`) o `null` si la
     * duración no viene informada.
     */
    val endMs: Long?
        get() = durationMs?.let { timeMs + it }

    /**
     * Fin de la palabra [index] dentro de la línea: `duration_ms` manda; si no
     * viene, el inicio de la siguiente palabra; si es la última, el fin de la
     * línea (o `null` si tampoco hay: abierta).
     */
    fun wordEndMs(index: Int): Long? {
        val word = words.getOrNull(index) ?: return null
        word.durationMs?.let { return word.timeMs + it }
        words.getOrNull(index + 1)?.let { return it.timeMs }
        return endMs
    }

    fun toJson(): Map<String, Any?> = buildMap {
        put("time_ms", timeMs)
        durationMs?.let { put("duration_ms", it) }
        put("text", text)
        if (words.isNotEmpty()) {
            put("words", words.map { it.toJson() })
        }
    }

    companion object {
        fun fromJson(json: Map<String, Any?>): SyncedLine = SyncedLine(
            timeMs = JsonParse.longOr(
                json["time_ms"] ?: json["time"] ?: json["start_ms"],
                0L,
            ),
            durationMs = JsonParse.asLong(json["duration_ms"]),
            text = JsonParse.strOr(json["text"] ?: json["line"] ?: json["value"], ""),
            words = JsonParse.listAt(json, "words").map { SyncedWord.fromJson(it) },
        )
    }
}
