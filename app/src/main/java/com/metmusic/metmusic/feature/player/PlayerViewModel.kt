package com.metmusic.metmusic.feature.player

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

/**
 * Estado del reproductor para la UI.
 *
 * Mínimo en FASE 5B: [state] (incluye `hasTrack`) y alternar play/pausa. Las
 * acciones restantes (favorito, seek, next, previous, shuffle, repeat) se
 * exponen a medida que las fases de UI las consumen.
 */
@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val connection: PlayerConnection,
) : ViewModel() {

    val state: StateFlow<PlayerUiState> = connection.state

    fun togglePlayPause() = connection.togglePlayPause()
}
