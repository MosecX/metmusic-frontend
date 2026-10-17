package com.metmusic.metmusic.navigation

import kotlinx.serialization.Serializable

/**
 * Rutas tipadas de Navigation Compose.
 *
 * Los cuatro tabs ([Home], [Search], [Library], [Settings]) son destinos
 * top-level envueltos en [MetMusicShell]; [Player] es un modal full-screen
 * sin shell. Las rutas con parámetros (Album, Artist, Playlist, Mix) se
 * suman en 6E/6F.
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
}
