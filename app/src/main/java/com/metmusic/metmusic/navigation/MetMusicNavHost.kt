package com.metmusic.metmusic.navigation

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.metmusic.metmusic.core.ui.components.MetMusicTab
import com.metmusic.metmusic.feature.home.HomeScreen
import com.metmusic.metmusic.feature.library.LibraryScreen
import com.metmusic.metmusic.feature.player.ui.PlayerScreen
import com.metmusic.metmusic.feature.search.SearchScreen
import com.metmusic.metmusic.feature.settings.SettingsScreen

/**
 * Grafo de navegación de MetMusic.
 *
 * Los cuatro tabs son destinos top-level envueltos en [MetMusicShell]
 * (bottom bar + MiniPlayer compartidos); [Routes.Player] es un modal
 * full-screen sin shell. Cambiar de tab conserva el back stack de cada uno
 * (`saveState`/`restoreState`) para cuando aparezcan rutas hijas (6E/6F).
 * El back predictivo lo resuelve Navigation Compose (el Manifest habilita
 * `enableOnBackInvokedCallback`), por eso no hay BackHandler.
 */
@Composable
fun MetMusicNavHost(
    navController: NavHostController = rememberNavController(),
    modifier: Modifier = Modifier,
) {
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
                SearchScreen()
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
    }
}

/** Duración del cross-fade al cambiar de tab. */
private const val TAB_FADE_MS = 200

/** Duración del slide del Player modal. */
private const val PLAYER_SLIDE_MS = 300

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
