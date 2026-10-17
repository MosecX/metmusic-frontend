package com.metmusic.metmusic.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.ui.components.MetMusicBottomBar
import com.metmusic.metmusic.core.ui.components.MetMusicTab
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.feature.player.PlayerUiState
import com.metmusic.metmusic.feature.player.PlayerViewModel
import com.metmusic.metmusic.feature.player.ui.MiniPlayer

/**
 * Shell de los tabs: Scaffold con bottom bar y MiniPlayer flotante.
 *
 * El shell consume los insets del sistema (status bar arriba, nav bar en el
 * bottom bar), así que el contenido que se renderiza adentro no necesita
 * manejar insets propios. [MetMusicShellContent] es puro, para previews y
 * tests.
 */
@Composable
fun MetMusicShell(
    currentTab: MetMusicTab,
    onTabSelected: (MetMusicTab) -> Unit,
    onOpenPlayer: () -> Unit,
    content: @Composable () -> Unit,
) {
    val playerViewModel: PlayerViewModel = hiltViewModel()
    val playerState by playerViewModel.state.collectAsStateWithLifecycle()
    MetMusicShellContent(
        playerState = playerState,
        currentTab = currentTab,
        onTabSelected = onTabSelected,
        onOpenPlayer = onOpenPlayer,
        onPlayPause = playerViewModel::togglePlayPause,
        onNext = playerViewModel::next,
        content = content,
    )
}

/** Composición pura del shell (sin ViewModel). */
@Composable
fun MetMusicShellContent(
    playerState: PlayerUiState,
    currentTab: MetMusicTab,
    onTabSelected: (MetMusicTab) -> Unit,
    onOpenPlayer: () -> Unit,
    onPlayPause: () -> Unit,
    onNext: () -> Unit,
    content: @Composable () -> Unit,
) {
    Scaffold(
        containerColor = MetMusicColors.background,
        contentWindowInsets = WindowInsets.statusBars,
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .windowInsetsPadding(WindowInsets.navigationBars),
            ) {
                if (playerState.hasTrack) {
                    MiniPlayer(
                        state = playerState,
                        onPlayPause = onPlayPause,
                        onNext = onNext,
                        onClick = onOpenPlayer,
                    )
                }
                MetMusicBottomBar(
                    currentTab = currentTab,
                    onTabSelected = onTabSelected,
                )
            }
        },
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            content()
        }
    }
}
