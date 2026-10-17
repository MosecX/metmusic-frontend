package com.metmusic.metmusic.navigation

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.metmusic.metmusic.feature.search.SearchScreen

/** Grafo de navegación de MetMusic. Por ahora, solo la búsqueda. */
@Composable
fun MetMusicNavHost(
    navController: NavHostController = rememberNavController(),
    modifier: Modifier = Modifier,
) {
    NavHost(
        navController = navController,
        startDestination = Routes.Search,
        modifier = modifier,
    ) {
        composable<Routes.Search> {
            SearchScreen()
        }
    }
}
