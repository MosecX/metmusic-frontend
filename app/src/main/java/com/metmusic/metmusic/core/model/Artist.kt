package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.ImageUtils
import com.metmusic.metmusic.core.util.JsonParse

/**
 * Un artista tal como lo devuelve el backend.
 *
 * Sin `@Serializable`: ver la nota en [Album] (contiene modelos no
 * serializables y solo se construye con [fromJson]).
 */
data class Artist(
    val artistId: String,
    val name: String,
    val picture: String? = null,
    val bio: String? = null,
    val albums: List<Album> = emptyList(),
    val topTracks: List<Track> = emptyList(),
    val thumbnails: List<Thumbnail> = emptyList(),
) {
    /** Mejor imagen disponible: `picture` del backend o la miniatura del catálogo. */
    val imageUrl: String
        get() = when {
            !picture.isNullOrBlank() -> ImageUtils.artistImageUrl(picture)
            thumbnails.isNotEmpty() -> ImageUtils.artistThumbnail(thumbnails)
            else -> ""
        }

    /** Candidatos de mejor a peor, sin URLs repetidas. */
    val imageUrlCandidates: List<String>
        get() {
            val candidates = buildList {
                if (!picture.isNullOrBlank()) add(ImageUtils.artistImageUrl(picture))
                thumbnails.forEach { thumbnail ->
                    if (thumbnail.url.isNotEmpty()) add(thumbnail.url)
                }
            }
            return candidates.distinct()
        }

    companion object {
        fun fromJson(json: Map<String, Any?>): Artist {
            val rawPicture = json["picture"] ?: json["image"] ?: json["picture_url"]
            return Artist(
                artistId = JsonParse.strOr(json["artist_id"] ?: json["id"], ""),
                name = JsonParse.strOr(json["name"] ?: json["artist"], "Desconocido"),
                picture = if (rawPicture is Map<*, *>) {
                    JsonParse.str(rawPicture["url"])
                } else {
                    JsonParse.str(rawPicture)
                },
                bio = JsonParse.str(json["bio"] ?: json["description"]),
                albums = JsonParse.listAt(json, "albums").map { Album.fromJson(it) },
                topTracks = JsonParse.listAt(json, "tracks").map { Track.fromJson(it) },
                thumbnails = Thumbnail.listFrom(json["thumbnails"]),
            )
        }
    }
}
