package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.ImageUtils
import com.metmusic.metmusic.core.util.JsonParse

/**
 * Un álbum tal como lo devuelve el backend.
 *
 * Sin `@Serializable` a propósito: contiene `Track`/`Thumbnail`, que son
 * clases planas con parseo manual, y el plugin de kotlinx.serialization exige
 * un serializer compile-time para cada propiedad. Este modelo solo se
 * construye con [fromJson] tolerante.
 */
data class Album(
    val albumId: String,
    val title: String,
    val artist: String? = null,
    val artistId: String? = null,
    val releaseDate: String? = null,
    val numberOfTracks: Int? = null,
    val durationSeconds: Int? = null,
    val thumbnails: List<Thumbnail> = emptyList(),
    val tracks: List<Track> = emptyList(),
    val copyright: String? = null,
    val upc: String? = null,
) {
    /** Año de lanzamiento (los primeros 4 dígitos de una fecha ISO). */
    val year: String
        get() = releaseDate?.take(4) ?: ""

    /** Miniatura para cards y headers. */
    val thumbnailUrl: String
        get() = ImageUtils.cardThumbnail(thumbnails)

    /** Cantidad de tracks: la declarada por el backend o el largo de [tracks]. */
    val trackCount: Int
        get() = numberOfTracks ?: tracks.size

    companion object {
        fun fromJson(json: Map<String, Any?>): Album = Album(
            albumId = JsonParse.strOr(json["album_id"] ?: json["id"], ""),
            title = JsonParse.strOr(json["title"], "Desconocido"),
            artist = JsonParse.str(json["artist"] ?: json["artist_name"]),
            artistId = JsonParse.str(json["artist_id"]),
            releaseDate = JsonParse.str(json["release_date"]),
            numberOfTracks = JsonParse.asInt(json["number_of_tracks"] ?: json["track_count"]),
            durationSeconds = JsonParse.asInt(json["duration_seconds"]),
            thumbnails = Thumbnail.listFrom(json["thumbnails"] ?: json["images"]),
            tracks = JsonParse.listAt(json, "tracks").map { Track.fromJson(it) },
            copyright = JsonParse.str(json["copyright"]),
            upc = JsonParse.str(json["upc"]),
        )
    }
}
