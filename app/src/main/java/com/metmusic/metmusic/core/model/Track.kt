package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.ImageUtils
import com.metmusic.metmusic.core.util.JsonParse

/** Una canción tal como la devuelve el backend. */
class Track(
    val trackId: String,
    val title: String,
    val artist: String? = null,
    val artistId: String? = null,
    val album: String? = null,
    val albumId: String? = null,
    val durationSeconds: Int = 0,
    val isrc: String? = null,
    val thumbnails: List<Thumbnail> = emptyList(),
    val quality: String? = null,
    val explicit: Boolean = false,
    val version: String? = null,
) {
    /** Título con el sufijo de versión cuando existe (ej. "Song (Remix)"). */
    val displayTitle: String
        get() = version?.trim()?.takeIf { it.isNotEmpty() }?.let { "$title ($it)" } ?: title

    val thumbnailUrl: String
        get() = ImageUtils.cardThumbnail(thumbnails)

    val listThumbnailUrl: String
        get() = ImageUtils.listThumbnail(thumbnails)

    fun toJson(): Map<String, Any?> = buildMap {
        put("track_id", trackId)
        put("title", title)
        artist?.let { put("artist", it) }
        artistId?.let { put("artist_id", it) }
        album?.let { put("album", it) }
        albumId?.let { put("album_id", it) }
        put("duration_seconds", durationSeconds)
        isrc?.let { put("isrc", it) }
        put("thumbnails", thumbnails.map { it.toJson() })
        quality?.let { put("quality", it) }
        put("explicit", explicit)
        version?.let { put("version", it) }
    }

    fun copyWith(
        trackId: String? = null,
        title: String? = null,
        artist: String? = null,
        artistId: String? = null,
        album: String? = null,
        albumId: String? = null,
        durationSeconds: Int? = null,
        isrc: String? = null,
        thumbnails: List<Thumbnail>? = null,
        quality: String? = null,
        explicit: Boolean? = null,
        version: String? = null,
    ): Track = Track(
        trackId = trackId ?: this.trackId,
        title = title ?: this.title,
        artist = artist ?: this.artist,
        artistId = artistId ?: this.artistId,
        album = album ?: this.album,
        albumId = albumId ?: this.albumId,
        durationSeconds = durationSeconds ?: this.durationSeconds,
        isrc = isrc ?: this.isrc,
        thumbnails = thumbnails ?: this.thumbnails,
        quality = quality ?: this.quality,
        explicit = explicit ?: this.explicit,
        version = version ?: this.version,
    )

    override fun equals(other: Any?): Boolean =
        other is Track && other.trackId == trackId

    override fun hashCode(): Int = trackId.hashCode()

    companion object {
        fun fromJson(json: Map<String, Any?>): Track = Track(
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
            thumbnails = Thumbnail.listFrom(json["thumbnails"] ?: json["images"]),
            quality = JsonParse.str(json["quality"]),
            explicit = JsonParse.boolOr(json["explicit"], false),
            version = JsonParse.str(json["version"]),
        )
    }
}
