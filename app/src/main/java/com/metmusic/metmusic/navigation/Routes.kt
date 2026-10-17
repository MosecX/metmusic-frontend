package com.metmusic.metmusic.navigation

import kotlinx.serialization.Serializable

/**
 * Rutas tipadas de Navigation Compose.
 *
 * Los cuatro tabs ([Home], [Search], [Library], [Settings]) son destinos
 * top-level envueltos en [MetMusicShell]; [Player] es un modal full-screen
 * sin shell. 6E-1 suma las details de catálogo ([Album], [Artist],
 * [Playlist]), 6E-2 el detalle editable de una playlist propia
 * ([UserPlaylist]) y 6F la estación radial ([Mix]).
 */
@Serializable
sealed interface Routes {

    /** Tab Home (explore). */
    @Serializable
    data object Home : Routes

    /** Tab Buscar. */
    @Serializable
    data object Search : Routes

    /** Tab Biblioteca (favoritos, playlists, historial). */
    @Serializable
    data object Library : Routes

    /** Tab Ajustes. */
    @Serializable
    data object Settings : Routes

    /** Player full-screen (slide-up, sin bottom bar). */
    @Serializable
    data object Player : Routes

    /** Detalle de álbum (`GET /api/albums/{albumId}`). */
    @Serializable
    data class Album(val albumId: String) : Routes

    /** Detalle de artista (`GET /api/artists/{artistId}`). */
    @Serializable
    data class Artist(val artistId: String) : Routes

    /** Detalle de playlist editorial (`GET /api/playlists/{playlistId}`). */
    @Serializable
    data class Playlist(val playlistId: String) : Routes

    /** Detalle editable de una playlist propia (`/api/user/playlists/{playlistId}`). */
    @Serializable
    data class UserPlaylist(val playlistId: String) : Routes

    /**
     * Estación radial generada desde un track semilla
     * (`GET /api/tracks/{trackId}/radio`).
     *
     * Ruta fuera del shell, con slide-up/down 300 ms, back propio y sin
     * bottom bar ni MiniPlayer.
     */
    @Serializable
    data class Mix(val trackId: String) : Routes
}
