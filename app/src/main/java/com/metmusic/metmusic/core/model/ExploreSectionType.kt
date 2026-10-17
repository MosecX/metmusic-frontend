package com.metmusic.metmusic.core.model

/** Tipo de contenido de una sección de Explore. */
enum class ExploreSectionType(val value: String) {
    TRACKS("tracks"),
    ALBUMS("albums"),
    ARTISTS("artists"),
    PLAYLISTS("playlists"),
    UNKNOWN("unknown");

    companion object {
        /** Tolerante: acepta los alias del backend (`songs`, `charts`...). */
        fun parse(raw: String?): ExploreSectionType = when (raw.orEmpty().lowercase()) {
            "tracks", "songs", "charts" -> TRACKS
            "albums", "releases", "new_releases" -> ALBUMS
            "artists" -> ARTISTS
            "playlists" -> PLAYLISTS
            else -> UNKNOWN
        }
    }
}
