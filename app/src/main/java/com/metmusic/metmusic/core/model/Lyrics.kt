package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/** Resultado de `GET /api/lyrics/{trackId}`. */
data class Lyrics(
    /**
     * Texto plano. Siempre presente en el contrato; única fuente cuando
     * [level] es [LyricsSyncLevel.NONE].
     */
    val lyrics: String? = null,

    /** `sync_level != "none"` (compatibilidad; redundante con [level]). */
    val isSynced: Boolean = false,

    /**
     * Líneas ordenadas por `time_ms`. Las líneas vacías (silencios) se
     * filtran en el parseo.
     */
    val syncedLines: List<SyncedLine> = emptyList(),

    val lrc: String? = null,
    val trackId: String? = null,

    /** Valor crudo de `sync_level` (`word` | `line` | `none`). */
    val syncLevel: String? = null,

    /** Fuente diagnóstica (`lyricsplus` | `spotycovs` | `lrclib`). */
    val provider: String? = null,

    /** Fuente upstream real (qApple, Spotify…). Informativo. */
    val source: String? = null,
) {
    val hasLyrics: Boolean
        get() = (lyrics?.trim()?.isNotEmpty() == true) || syncedLines.isNotEmpty()

    val hasSynced: Boolean
        get() = isSynced && syncedLines.isNotEmpty()

    /**
     * Nivel de sincronía que manda para el render. Se lee de la respuesta;
     * si un payload viejo no lo trae, se infiere de los datos.
     */
    val level: LyricsSyncLevel
        get() = when (syncLevel?.lowercase()) {
            "word" -> LyricsSyncLevel.WORD
            "line" -> LyricsSyncLevel.LINE
            "none" -> LyricsSyncLevel.NONE
            else -> when {
                syncedLines.any { it.words.isNotEmpty() } -> LyricsSyncLevel.WORD
                syncedLines.isNotEmpty() || isSynced -> LyricsSyncLevel.LINE
                else -> LyricsSyncLevel.NONE
            }
        }

    /**
     * Índice de la línea que suena en [posMs], según el contrato:
     * `time_ms <= pos < time_ms + duration_ms` (o hasta la siguiente línea si
     * `duration_ms` es `null`). Devuelve -1 antes del primer verso o en los
     * silencios entre líneas con duración.
     */
    fun activeLineIndex(posMs: Long): Int {
        var index = -1
        for (i in syncedLines.indices) {
            if (syncedLines[i].timeMs > posMs) break
            index = i
        }
        if (index < 0) return -1
        val line = syncedLines[index]
        val nextStart = syncedLines.getOrNull(index + 1)?.timeMs
        val end = line.endMs ?: nextStart
        if (end != null && posMs >= end) return -1
        return index
    }

    companion object {
        private val LRC_REGEX = Regex("""\[(\d+):(\d+)(?:[.:](\d+))?\](.*)""")

        fun fromJson(json: Map<String, Any?>): Lyrics {
            val rawLevel = JsonParse.str(json["sync_level"])?.lowercase()
            var lines = JsonParse.listAt(json, "synced_lines")
                .map { SyncedLine.fromJson(it) }
                .toMutableList()
            val lrc = JsonParse.str(json["lrc"])
            val synced = JsonParse.boolOr(
                json["is_synced"],
                rawLevel != null && rawLevel != "none",
            )
            // El LRC sólo se usa como respaldo de compatibilidad: con
            // `sync_level: none` no se derivan tiempos (suele venir null igual).
            if (lines.isEmpty() && synced && lrc != null && rawLevel != "none") {
                lines = parseLrc(lrc).toMutableList()
            }
            lines.sortBy { it.timeMs }
            // Las líneas de texto vacío son silencios: no aportan al render.
            val visible = lines.filter { it.text.trim().isNotEmpty() }
            return Lyrics(
                lyrics = JsonParse.str(json["lyrics"] ?: json["plain_lyrics"]),
                isSynced = synced || visible.isNotEmpty(),
                syncedLines = visible,
                lrc = lrc,
                trackId = JsonParse.str(json["track_id"]),
                syncLevel = rawLevel,
                provider = JsonParse.str(json["provider"]),
                source = JsonParse.str(json["source"]),
            )
        }

        /** Parser de compatibilidad `[mm:ss.xx] texto` (y `[mm:ss:xx]`). */
        private fun parseLrc(lrc: String): List<SyncedLine> {
            val result = mutableListOf<SyncedLine>()
            for (raw in lrc.split('\n')) {
                val match = LRC_REGEX.find(raw.trim()) ?: continue
                val minutes = match.groupValues[1].toIntOrNull() ?: 0
                val seconds = match.groupValues[2].toIntOrNull() ?: 0
                val fractionRaw = match.groupValues[3].takeIf { it.isNotEmpty() } ?: "0"
                val fraction = fractionRaw.toIntOrNull() ?: 0
                val ms = if (fractionRaw.length == 2) fraction * 10 else fraction
                val text = match.groupValues[4].trim()
                if (text.isEmpty()) continue
                result += SyncedLine(
                    timeMs = minutes * 60_000L + seconds * 1_000L + ms,
                    text = text,
                )
            }
            return result
        }
    }
}
