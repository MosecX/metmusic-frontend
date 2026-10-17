package com.metmusic.metmusic.core.network

/** Constantes de red del backend MetMusic. */
object ApiConstants {

    /** URL base del backend. Retrofit exige que termine en '/'. */
    const val BASE_URL: String = "https://tdl-qbz-api.metmusic.qzz.io/"

    /**
     * Token Bearer precargado, extraído del archivo archivado
     * `old-flutter/lib/core/constants/api_constants.dart`.
     *
     * Desvío acotado de esta rebanada: EncryptedSharedPreferences llega en la
     * fase de Settings/almacenamiento; hasta entonces la búsqueda usa esta
     * constante para funcionar.
     */
    const val DEFAULT_API_TOKEN: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtZXRtdXNpYy1hZG1pbi10b2tlbiIsIm5hbWUiOiJUT0tFTiIsInJvbGUiOiJhZG1pbiIsImFwcCI6Im1ldG11c2ljLWFuZHJvaWQiLCJ2ZXJzaW9uIjoiMS4wLjAiLCJwZXJtaXNzaW9ucyI6WyJzdHJlYW0iLCJzZWFyY2giLCJtZXRhZGF0YSIsInBsYXlsaXN0cyIsImhpc3RvcnkiLCJmYXZvcml0ZXMiLCJseXJpY3MiLCJjYW52YXMiLCJleHBsb3JlIl0sImRldmljZV9pZCI6ImEzZjhjMmQxZTViNzA5NDRmNmIyYThkOWMxZTNmNWE3YjlkMGUyZjRhNjhiMGMyZDRlNmY4YTBiMmM0ZDZlOGYwIiwic2Vzc2lvbl9pZCI6IjFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzIiwiaXNzdWVkX2J5IjoibWV0bXVzaWMtYmFja2VuZCIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJ0aWVyIjoiaGlyZXMiLCJtYXhfcXVhbGl0eSI6IkhJX1JFUyIsInByb3ZpZGVycyI6WyJxb2J1eiIsInRpZGFsIl0sImZlYXR1cmVzIjpbInN0cmVhbWluZyIsIm9mZmxpbmUiLCJseXJpY3Nfc3luYyIsImNhbnZhcyIsImVxdWFsaXplciIsInNjcm9iYmxpbmciXSwiaWF0IjoxNzUwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTksIm5iZiI6MTc1MDAwMDAwMCwianRpIjoiNGY1YTZiN2M4ZDllMGYxZjJhM2I0YzVkNmU3ZjgwOTFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjAiLCJhdWQiOiJ0ZGwtcWJ6LWFwaS5tZXRtdXNpYy5xenouaW8iLCJpc3MiOiJtZXRtdXNpYy1hdXRoIiwiZXh0cmFfZGF0YSI6eyJyZWdpb24iOiJMQVRBTSIsImxhbmd1YWdlIjoiZXMiLCJ0aGVtZSI6ImRhcmsiLCJhdWRpb19jb2RlY19wcmVmZXJlbmNlIjpbImZsYWMiLCJtcDQiLCJvcHVzIl0sIm1heF9iaXRyYXRlIjo5MjE2LCJzYW1wbGVfcmF0ZXMiOls0NDEwMCw0ODAwMCw5NjAwMCwxOTIwMDBdLCJiaXRfZGVwdGhzIjpbMTYsMjQsMzJdLCJjYW52YXNfZW5hYmxlZCI6dHJ1ZSwic2VnbWVudF9wcm94eSI6ZmFsc2UsImNhY2hlX3R0bCI6MzYwMCwic2Vzc2lvbl90b2tlbiI6ImUxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzYTRiNWM2ZDdlOGY5YTBiMWMyZDNlNGY1YTZiNyIsInJlZnJlc2hfdG9rZW4iOiIxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzEiLCJhcGlfa2V5X2ludGVybmFsIjoiYTliOGM3ZDZlNWY0YTNiMmMxZDBlOWY4YTdiNmM1ZDRlM2YyYTFiMGM5ZDhlN2Y2YTViNGMzZDJlMWYwIn19.9rMELXs3SAFkQ6960Reln8keTY9fo9YgK5JcL7I1Kzw"

    const val CONNECT_TIMEOUT_SECONDS: Long = 15
    const val READ_TIMEOUT_SECONDS: Long = 30
    const val WRITE_TIMEOUT_SECONDS: Long = 15
}

/** Endpoints del backend (port 1:1 de ApiConstants de la app Flutter). */
object ApiEndpoints {
    const val HEALTH = "/api/health"
    const val SEARCH = "/api/search"

    fun track(id: String) = "/api/tracks/$id"
    fun stream(id: String) = "/api/stream/$id"
    fun album(id: String) = "/api/albums/$id"
    fun artist(id: String) = "/api/artists/$id"
    fun playlist(uuid: String) = "/api/playlists/$uuid"
    fun lyrics(id: String) = "/api/lyrics/$id"
    fun canvas(id: String) = "/api/canvas/$id"
    fun radio(id: String) = "/api/tracks/$id/radio"

    const val EXPLORE_HOME = "/api/explore/home"
    const val EXPLORE_NEW_RELEASES = "/api/explore/new_releases"
    const val EXPLORE_CHARTS = "/api/explore/charts"
    const val EXPLORE_MOODS = "/api/explore/moods"

    const val USER_PLAYLISTS = "/api/user/playlists"
    fun userPlaylist(id: String) = "/api/user/playlists/$id"
    fun userPlaylistTracks(id: String) = "/api/user/playlists/$id/tracks"
    fun userPlaylistTrack(id: String, trackId: String) = "/api/user/playlists/$id/tracks/$trackId"
    fun userPlaylistReorder(id: String) = "/api/user/playlists/$id/reorder"

    const val USER_HISTORY = "/api/user/history"
    const val USER_FAVORITES = "/api/user/favorites"
    fun userFavorite(trackId: String) = "/api/user/favorites/$trackId"
    const val USER_FAVORITES_CHECK = "/api/user/favorites/check"

    const val CACHE = "/api/cache"
}
