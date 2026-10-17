package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/**
 * Respuesta de `GET /api/tracks/{trackId}/radio`.
 *
 * Trae la estación y TODAS sus pistas de una (sin paginar; el backend cachea
 * 15 min por pista). El primer item es la pista semilla con la que se pidió
 * el radio.
 */
data class RadioStation(
    val trackId: String,
    val mix: RadioMix,
    val items: List<Track>,
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): RadioStation = RadioStation(
            trackId = JsonParse.strOr(json["track_id"], ""),
            mix = RadioMix.fromJson(JsonParse.mapOf(json["mix"])),
            items = JsonParse.listAt(json, "items").map { Track.fromJson(it) },
        )
    }
}
