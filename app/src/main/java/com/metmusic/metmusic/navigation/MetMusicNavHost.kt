package com.metmusic.metmusic.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.metmusic.metmusic.core.ui.components.MetMusicTab
import com.metmusic.metmusic.feature.album.AlbumDetailScreen
import com.metmusic.metmusic.feature.artist.ArtistDetailScreen
import com.metmusic.metmusic.feature.home.HomeScreen
import com.metmusic.metmusic.feature.library.LibraryScreen
import com.metmusic.metmusic.feature.player.PlayerViewModel
import com.metmusic.metmusic.feature.player.ui.PlayerScreen
import com.metmusic.metmusic.feature.playlist.PlaylistDetailScreen
import com.metmusic.metmusic.feature.search.SearchScreen
import com.metmusic.metmusic.feature.settings.SettingsScreen

/**
 * Grafo de navegación de MetMusic.
 *
 * Los cuatro tabs son destinos top-level envueltos en [MetMusicShell]
 * (bottom bar + MiniPlayer compartidos); [Routes.Player] es un modal
 * full-screen sin shell. Las details de catálogo (6E-1) también van fuera
 * del shell, con slide-up/down propio. Cambiar de tab conserva el back
 * stack de cada uno (`saveState`/`restoreState`) para cuando aparezcan
 * rutas hijas (6E/6F).
 * El back predictivo lo resuelve Navigation Compose (el Manifest habilita
 * `enableOnBackInvokedCallback`), por eso no hay BackHandler.
 */
@Composable
fun MetMusicNavHost(
    navController: NavHostController = rememberNavController(),
    modifier: Modifier = Modifier,
) {
    val playerViewModel: PlayerViewModel = hiltViewModel()
    NavHost(
        navController = navController,
        startDestination = Routes.Home,
        modifier = modifier,
    ) {
        composable<Routes.Home>(
            enterTransition = { fadeIn(tween(TAB_FADE_MS)) },
            exitTransition = { fadeOut(tween(TAB_FADE_MS)) },
        ) {
            MetMusicShell(
                currentTab = MetMusicTab.HOME,
                onTabSelected = navController::navigateToTab,
                onOpenPlayer = { navController.navigate(Routes.Player) },
            ) {
                HomeScreen(
                    onGoToSearch = { navController.navigateToTab(MetMusicTab.SEARCH) },
                    onAlbumClick = { albumId -> navController.navigate(Routes.Album(albumId)) },
                    onArtistClick = { artistId ->
                        navController.navigate(Routes.Artist(artistId))
                    },
                    onPlaylistClick = { playlistId ->
                        navController.navigate(Routes.Playlist(playlistId))
                    },
                    onPlayTracks = { tracks, index -> playerViewModel.playQueue(tracks, index) },
                )
            }
        }
        composable<Routes.Search>(
            enterTransition = { fadeIn(tween(TAB_FADE_MS)) },
            exitTransition = { fadeOut(tween(TAB_FADE_MS)) },
        ) {
            MetMusicShell(
                currentTab = MetMusicTab.SEARCH,
                onTabSelected = navController::navigateToTab,
                onOpenPlayer = { navController.navigate(Routes.Player) },
            ) {
                SearchScreen(
                    onAlbumClick = { albumId -> navController.navigate(Routes.Album(albumId)) },
                    onArtistClick = { artistId ->
                        navController.navigate(Routes.Artist(artistId))
                    },
                    onPlaylistClick = { playlistId ->
                        navController.navigate(Routes.Playlist(playlistId))
                    },
                )
            }
        }
        composable<Routes.Library>(
            enterTransition = { fadeIn(tween(TAB_FADE_MS)) },
            exitTransition = { fadeOut(tween(TAB_FADE_MS)) },
        ) {
            MetMusicShell(
                currentTab = MetMusicTab.LIBRARY,
                onTabSelected = navController::navigateToTab,
                onOpenPlayer = { navController.navigate(Routes.Player) },
            ) {
                LibraryScreen(
                    onGoToSearch = { navController.navigateToTab(MetMusicTab.SEARCH) },
                )
            }
        }
        composable<Routes.Settings>(
            enterTransition = { fadeIn(tween(TAB_FADE_MS)) },
            exitTransition = { fadeOut(tween(TAB_FADE_MS)) },
        ) {
            MetMusicShell(
                currentTab = MetMusicTab.SETTINGS,
                onTabSelected = navController::navigateToTab,
                onOpenPlayer = { navController.navigate(Routes.Player) },
            ) {
                SettingsScreen()
            }
        }
        composable<Routes.Player>(
            enterTransition = {
                slideIntoContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Up,
                    animationSpec = tween(PLAYER_SLIDE_MS),
                )
            },
            exitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(PLAYER_SLIDE_MS),
                )
            },
            popExitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(PLAYER_SLIDE_MS),
                )
            },
        ) {
            PlayerScreen(
                onClose = { navController.popBackStack() },
            )
        }
        composable<Routes.Album>(
            enterTransition = {
                slideIntoContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Up,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            exitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            popExitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
        ) {
            AlbumDetailScreen(
                onBack = { navController.popBackStack() },
                onArtistClick = { artistId ->
                    navController.navigate(Routes.Artist(artistId))
                },
                onPlayTracks = { tracks, index -> playerViewModel.playQueue(tracks, index) },
            )
        }
        composable<Routes.Artist>(
            enterTransition = {
                slideIntoContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Up,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            exitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            popExitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
        ) {
            ArtistDetailScreen(
                onBack = { navController.popBackStack() },
                onAlbumClick = { albumId ->
                    navController.navigate(Routes.Album(albumId))
                },
                onPlayTracks = { tracks, index -> playerViewModel.playQueue(tracks, index) },
            )
        }
        composable<Routes.Playlist>(
            enterTransition = {
                slideIntoContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Up,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            exitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
            popExitTransition = {
                slideOutOfContainer(
                    towards = AnimatedContentTransitionScope.SlideDirection.Down,
                    animationSpec = tween(DETAIL_SLIDE_MS),
                )
            },
        ) {
            PlaylistDetailScreen(
                onBack = { navController.popBackStack() },
                onPlayTracks = { tracks, index -> playerViewModel.playQueue(tracks, index) },
            )
        }
    }
}

/** Duración del cross-fade al cambiar de tab. */
private const val TAB_FADE_MS = 200

/** Duración del slide del Player modal. */
private const val PLAYER_SLIDE_MS = 300

/** Duración del slide de las details de catálogo (Album/Artist/Playlist). */
private const val DETAIL_SLIDE_MS = 300

/**
 * Cambia de tab con `launchSingleTop`, preservando el estado y el back stack
 * de cada tab ([findStartDestination] como raíz del pop).
 */
private fun NavHostController.navigateToTab(tab: MetMusicTab) {
    if (isCurrentTab(tab)) return
    navigate(tab.route) {
        popUpTo(this@navigateToTab.graph.findStartDestination().id) {
            saveState = true
        }
        launchSingleTop = true
        restoreState = true
    }
}

/** `true` cuando el tab indicado ya está sobre el tope del back stack. */
private fun NavHostController.isCurrentTab(tab: MetMusicTab): Boolean = when (tab) {
    MetMusicTab.HOME -> currentDestination?.hasRoute<Routes.Home>() == true
    MetMusicTab.SEARCH -> currentDestination?.hasRoute<Routes.Search>() == true
    MetMusicTab.LIBRARY -> currentDestination?.hasRoute<Routes.Library>() == true
    MetMusicTab.SETTINGS -> currentDestination?.hasRoute<Routes.Settings>() == true
}
