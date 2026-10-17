package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/**
 * Metadatos de la estación (mix) devuelta por `GET /api/tracks/{id}/radio`.
 */
data class RadioMix(
    val id: String,
    val title: String,
    /** Artista principal de la estación (`sub_title` del payload). */
    val subTitle: String? = null,
    val description: String? = null,
    /**
     * Imagen firmada de Tidal. Si el backend la refresca cada 15 min, una
     * URL vieja vuelve a funcionar re-pidiendo el radio.
     */
    val imageUrl: String? = null,
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): RadioMix = RadioMix(
            id = JsonParse.strOr(json["id"], ""),
            title = JsonParse.strOr(json["title"], ""),
            subTitle = JsonParse.str(json["sub_title"]),
            description = JsonParse.str(json["description"]),
            imageUrl = JsonParse.str(json["image_url"]),
        )
    }
}
