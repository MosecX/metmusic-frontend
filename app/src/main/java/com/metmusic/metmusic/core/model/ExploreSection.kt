package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed

/** Una fila de la Home (carrusel de álbumes, lista de tracks, etc.). */
data class ExploreSection(
    val id: String,
    val title: String,
    val type: ExploreSectionType,
    val tracks: List<Track> = emptyList(),
    val albums: List<Album> = emptyList(),
    val artists: List<Artist> = emptyList(),
    val playlists: List<Playlist> = emptyList(),
) {
    /** `true` cuando la sección no trajo contenido de ninguna categoría. */
    val isEmpty: Boolean
        get() = tracks.isEmpty() && albums.isEmpty() && artists.isEmpty() && playlists.isEmpty()

    companion object {
        /**
         * Parsea una sección de forma tolerante.
         *
         * Acepta `{title, type, items}` o directamente una lista de items; en
         * el segundo caso el tipo se infiere del contenido.
         */
        fun fromJson(key: String, value: Any?): ExploreSection {
            var title = humanize(key)
            var type = ExploreSectionType.parse(key)

            val items = when (value) {
                is List<*> -> JsonParse.maps(value)
                is Map<*, *> -> {
                    val map = value.stringKeyed()
                    title = JsonParse.strOr(map["title"] ?: map["name"] ?: map["heading"], title)
                    type = ExploreSectionType.parse(
                        JsonParse.str(map["type"] ?: map["section_type"]) ?: key,
                    )
                    val raw = map["items"]
                        ?: map["tracks"]
                        ?: map["albums"]
                        ?: map["artists"]
                        ?: map["playlists"]
                        ?: map["data"]
                        ?: emptyList<Any?>()
                    val extracted = JsonParse.maps(raw)
                    if (map["tracks"] != null) type = ExploreSectionType.TRACKS
                    if (map["albums"] != null) type = ExploreSectionType.ALBUMS
                    if (map["artists"] != null) type = ExploreSectionType.ARTISTS
                    if (map["playlists"] != null) type = ExploreSectionType.PLAYLISTS
                    extracted
                }
                else -> return ExploreSection(id = key, title = title, type = ExploreSectionType.UNKNOWN)
            }

            if (type == ExploreSectionType.UNKNOWN && items.isNotEmpty()) {
                type = detectType(items.first())
            }

            return ExploreSection(
                id = key,
                title = title,
                type = type,
                tracks = if (type == ExploreSectionType.TRACKS) {
                    items.map { Track.fromJson(it) }
                } else {
                    emptyList()
                },
                albums = if (type == ExploreSectionType.ALBUMS) {
                    items.map { Album.fromJson(it) }
                } else {
                    emptyList()
                },
                artists = if (type == ExploreSectionType.ARTISTS) {
                    items.map { Artist.fromJson(it) }
                } else {
                    emptyList()
                },
                playlists = if (type == ExploreSectionType.PLAYLISTS) {
                    items.map { Playlist.fromJson(it) }
                } else {
                    emptyList()
                },
            )
        }

        /** Infiere el tipo del contenido de un item sin `type` explícito. */
        private fun detectType(item: Map<String, Any?>): ExploreSectionType = when {
            item.containsKey("track_id") || item.containsKey("isrc") -> ExploreSectionType.TRACKS
            item.containsKey("album_id") -> ExploreSectionType.ALBUMS
            item.containsKey("artist_id") -> ExploreSectionType.ARTISTS
            item.containsKey("playlist_id") || item.containsKey("uuid") -> ExploreSectionType.PLAYLISTS
            item.containsKey("duration_seconds") -> ExploreSectionType.TRACKS
            else -> ExploreSectionType.UNKNOWN
        }

        /** "new_releases" -> "New releases"; clave vacía -> "Explorar". */
        private fun humanize(key: String): String {
            val spaced = key.replace('_', ' ').trim()
            if (spaced.isEmpty()) return "Explorar"
            return spaced.replaceFirstChar { it.uppercaseChar() }
        }
    }
}
