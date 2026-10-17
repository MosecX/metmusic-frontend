package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/**
 * Metadatos completos de una pista (`GET /api/tracks/{trackId}`).
 *
 * A diferencia de [Track] (que sólo trae lo que muestran las listas), éste
 * parsea el TrackSchema entero: ISRC, BPM, popularidad, copyright y si está
 * lista para stream.
 */
data class TrackDetails(
    val trackId: String,
    val title: String,
    val artist: String? = null,
    val artistId: String? = null,
    val album: String? = null,
    val albumId: String? = null,
    val durationSeconds: Int = 0,
    val isrc: String? = null,
    val quality: String? = null,
    val version: String? = null,
    val copyright: String? = null,
    val popularity: Double? = null,
    val bpm: Double? = null,
    val peak: Double? = null,
    val explicit: Boolean = false,
    val streamReady: Boolean = false,
) {
    val duration: Duration
        get() = durationSeconds.seconds

    companion object {
        fun fromJson(json: Map<String, Any?>): TrackDetails = TrackDetails(
            trackId = JsonParse.strOr(json["track_id"] ?: json["id"], ""),
            title = JsonParse.strOr(json["title"], "Desconocido"),
            artist = JsonParse.str(json["artist"] ?: json["artist_name"]),
            artistId = JsonParse.str(json["artist_id"]),
            album = JsonParse.str(json["album"] ?: json["album_title"]),
            albumId = JsonParse.str(json["album_id"]),
            durationSeconds = JsonParse.intOr(
                json["duration_seconds"] ?: json["duration"],
                0,
            ),
            isrc = JsonParse.str(json["isrc"]),
            quality = JsonParse.str(json["quality"]),
            version = JsonParse.str(json["version"]),
            copyright = JsonParse.str(json["copyright"]),
            popularity = JsonParse.asDouble(json["popularity"]),
            bpm = JsonParse.asDouble(json["bpm"]),
            peak = JsonParse.asDouble(json["peak"]),
            explicit = JsonParse.boolOr(json["explicit"], false),
            streamReady = JsonParse.boolOr(json["stream_ready"], false),
        )
    }
}
