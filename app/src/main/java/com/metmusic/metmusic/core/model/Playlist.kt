package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.ImageUtils
import com.metmusic.metmusic.core.util.JsonParse

/**
 * Una playlist tal como la devuelve el backend (editorial o de usuario).
 *
 * Sin `@Serializable`: ver la nota en [Album] (contiene modelos no
 * serializables y solo se construye con [fromJson]).
 */
data class Playlist(
    val playlistId: String,
    val title: String,
    val creator: String? = null,
    val description: String? = null,
    val numberOfTracks: Int? = null,
    val thumbnails: List<Thumbnail> = emptyList(),
    val tracks: List<Track> = emptyList(),
) {
    /** Miniatura para cards y headers. */
    val thumbnailUrl: String
        get() = ImageUtils.cardThumbnail(thumbnails)

    /** Cantidad de tracks: la declarada por el backend o el largo de [tracks]. */
    val trackCount: Int
        get() = numberOfTracks ?: tracks.size

    companion object {
        fun fromJson(json: Map<String, Any?>): Playlist = Playlist(
            playlistId = JsonParse.strOr(json["playlist_id"] ?: json["uuid"] ?: json["id"], ""),
            title = JsonParse.strOr(json["title"] ?: json["name"], "Sin título"),
            creator = JsonParse.str(json["creator"] ?: json["owner"]),
            description = JsonParse.str(json["description"]),
            numberOfTracks = JsonParse.asInt(json["number_of_tracks"] ?: json["track_count"]),
            thumbnails = Thumbnail.listFrom(json["thumbnails"] ?: json["images"]),
            tracks = JsonParse.listAt(json, "tracks").map { Track.fromJson(it) },
        )
    }
}
