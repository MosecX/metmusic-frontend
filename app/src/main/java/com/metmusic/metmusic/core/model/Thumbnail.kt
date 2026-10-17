package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed

/** Una imagen disponible para un recurso (track, álbum, artista, playlist). */
class Thumbnail(
    val url: String,
    val width: Int? = null,
    val height: Int? = null,
) {
    fun toJson(): Map<String, Any?> = buildMap {
        put("url", url)
        width?.let { put("width", it) }
        height?.let { put("height", it) }
    }

    override fun equals(other: Any?): Boolean =
        other is Thumbnail && other.url == url && other.width == width

    override fun hashCode(): Int = 31 * url.hashCode() + (width ?: 0)

    companion object {
        fun fromJson(json: Map<String, Any?>): Thumbnail = Thumbnail(
            url = JsonParse.strOr(json["url"], ""),
            width = JsonParse.asInt(json["width"]),
            height = JsonParse.asInt(json["height"]),
        )

        /** Tolerante: acepta `[{url,width,height}]` o `["url", ...]`. */
        fun listFrom(value: Any?): List<Thumbnail> {
            val list = value as? List<*> ?: return emptyList()
            return list.mapNotNull { item ->
                when (item) {
                    is Map<*, *> -> fromJson(item.stringKeyed())
                    is String -> if (item.isNotEmpty()) Thumbnail(url = item) else null
                    else -> null
                }
            }
        }
    }
}
