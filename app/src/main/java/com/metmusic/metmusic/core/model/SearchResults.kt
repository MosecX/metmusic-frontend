package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/** Pestañas de búsqueda soportadas por GET /api/search. */
enum class SearchType(val value: String, val label: String) {
    ALL("all", "Todo"),
    TRACKS("tracks", "Canciones"),
    ALBUMS("albums", "Álbumes"),
    ARTISTS("artists", "Artistas"),
    PLAYLISTS("playlists", "Playlists");
}

/** Resultado agregado de GET /api/search. */
data class SearchResults(
    val tracks: List<Track> = emptyList(),
    val albums: List<Album> = emptyList(),
    val artists: List<Artist> = emptyList(),
    val playlists: List<Playlist> = emptyList(),
    val totalResults: Int = 0,
    val query: String = "",
) {
    /** `true` cuando no llegó ningún resultado de ninguna categoría. */
    val isEmpty: Boolean
        get() = tracks.isEmpty() && albums.isEmpty() && artists.isEmpty() && playlists.isEmpty()

    /** Cantidad de resultados recibidos (suma de las cuatro categorías). */
    val count: Int
        get() = tracks.size + albums.size + artists.size + playlists.size

    companion object {
        val EMPTY = SearchResults()

        fun fromJson(json: Map<String, Any?>, query: String): SearchResults = SearchResults(
            tracks = JsonParse.listAt(json, "tracks").map { Track.fromJson(it) },
            albums = JsonParse.listAt(json, "albums").map { Album.fromJson(it) },
            artists = JsonParse.listAt(json, "artists").map { Artist.fromJson(it) },
            playlists = JsonParse.listAt(json, "playlists").map { Playlist.fromJson(it) },
            totalResults = JsonParse.intOr(json["total_results"], 0),
            query = query,
        )
    }
}
