package com.metmusic.metmusic.feature.library

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.List
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.metmusic.metmusic.core.ui.components.MetMusicEmptyState

/**
 * Biblioteca minimal (6A-2): empty state con CTA a la búsqueda. La
 * Biblioteca real (favoritos, playlists, historial) llega en 6C.
 */
@Composable
fun LibraryScreen(
    onGoToSearch: () -> Unit,
    modifier: Modifier = Modifier,
) {
    MetMusicEmptyState(
        modifier = modifier.fillMaxSize(),
        title = "Tu biblioteca está vacía",
        subtitle = "Guardá favoritos y creá playlists desde la búsqueda.",
        icon = Icons.AutoMirrored.Outlined.List,
        actionLabel = "Buscar música",
        onAction = onGoToSearch,
    )
}
