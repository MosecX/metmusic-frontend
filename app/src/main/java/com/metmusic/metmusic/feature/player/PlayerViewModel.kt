package com.metmusic.metmusic.feature.player

import androidx.lifecycle.ViewModel
import com.metmusic.metmusic.core.model.Track
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.StateFlow

/**
 * Estado del reproductor para la UI.
 *
 * Mínimo en FASE 5B: [state] (incluye `hasTrack`), favorito del track activo
 * y alternar play/pausa y favorito. 6A-2 agrega [next] y [previous] para el
 * MiniPlayer; 6E-1 agrega [playQueue] y [playSingle] para reproducir desde
 * las pantallas de detalle; las restantes (seek, shuffle, repeat) llegan en
 * 6G con FullPlayer.
 */
@HiltViewModel
class PlayerViewModel @Inject constructor(
    private val connection: PlayerConnection,
) : ViewModel() {

    val state: StateFlow<PlayerUiState> = connection.state

    val isFavorite: StateFlow<Boolean> = connection.isFavorite

    fun togglePlayPause() = connection.togglePlayPause()

    fun toggleFavorite() = connection.toggleFavorite()

    fun next() = connection.next()

    fun previous() = connection.previous()

    /** Reproduce [tracks] desde [startIndex] (details de catálogo, 6E-1). */
    fun playQueue(tracks: List<Track>, startIndex: Int) =
        connection.playQueue(tracks, startIndex)

    /** Reproduce un único [track]. */
    fun playSingle(track: Track) = connection.playSingle(track)
}
