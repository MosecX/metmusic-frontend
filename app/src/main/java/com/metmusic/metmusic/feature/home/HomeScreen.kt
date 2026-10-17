package com.metmusic.metmusic.feature.home

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState

/**
 * Home minimal (6A-2): empty state con CTA a la búsqueda. La Home real
 * (explore, novedades, charts, moods, historial reciente) llega en 6B.
 */
@Composable
fun HomeScreen(
    onGoToSearch: () -> Unit,
    modifier: Modifier = Modifier,
) {
    MetMusicEmptyState(
        modifier = modifier.fillMaxSize(),
        title = "Tu Home está vacía",
        subtitle = "Explorá artistas, álbumes y playlists desde la búsqueda.",
        icon = Icons.Outlined.Home,
        actionLabel = "Buscar música",
        onAction = onGoToSearch,
    )
}
