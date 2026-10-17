package com.metmusic.metmusic.feature.player

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

/**
 * Estado del reproductor para la UI.
 *
 * Mínimo en FASE 5B: [state] (incluye `hasTrack`), favorito del track activo
 * y alternar play/pausa y favorito. Las acciones restantes (seek, next,
 * previous, shuffle, repeat) se exponen en 6G con FullPlayer.
 */
@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val connection: PlayerConnection,
) : ViewModel() {

    val state: StateFlow<PlayerUiState> = connection.state

    val isFavorite: StateFlow<Boolean> = connection.isFavorite

    fun togglePlayPause() = connection.togglePlayPause()

    fun toggleFavorite() = connection.toggleFavorite()
}
