package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.ImageUtils
import com.metmusic.metmusic.core.util.JsonParse

/**
 * Playlist creada por el usuario (`/api/user/playlists`).
 *
 * Sin `@Serializable`: ver la nota en [Album] (contiene `Track`, que se
 * construye con parseo manual).
 */
data class UserPlaylist(
    val playlistId: String,
    val name: String,
    val description: String? = null,
    val coverUrl: String? = null,
    val numberOfTracks: Int? = null,
    val tracks: List<Track> = emptyList(),
    val createdAt: String? = null,
    val updatedAt: String? = null,
) {
    /** Cantidad de tracks: la declarada por el backend o el largo de [tracks]. */
    val trackCount: Int
        get() = numberOfTracks ?: tracks.size

    /** Los thumbnails sintéticos derivan del `cover_url` local del usuario. */
    val syntheticThumbnails: List<Thumbnail>
        get() = coverUrl?.takeIf { it.isNotEmpty() }?.let { listOf(Thumbnail(it)) } ?: emptyList()

    /** Miniatura para cards y headers. */
    val thumbnailUrl: String
        get() = ImageUtils.cardThumbnail(syntheticThumbnails)

    companion object {
        fun fromJson(json: Map<String, Any?>): UserPlaylist = UserPlaylist(
            playlistId = JsonParse.strOr(json["id"] ?: json["playlist_id"] ?: json["uuid"], ""),
            name = JsonParse.strOr(json["name"] ?: json["title"], "Sin título"),
            description = JsonParse.str(json["description"]),
            coverUrl = JsonParse.str(json["cover_url"] ?: json["cover"]),
            numberOfTracks = JsonParse.asInt(json["track_count"] ?: json["number_of_tracks"]),
            tracks = JsonParse.listAt(json, "tracks").map { Track.fromJson(it) },
            createdAt = JsonParse.str(json["created_at"]),
            updatedAt = JsonParse.str(json["updated_at"]),
        )
    }
}
