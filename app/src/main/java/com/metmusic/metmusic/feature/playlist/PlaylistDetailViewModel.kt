package com.metmusic.metmusic.feature.playlist

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.PlaylistRepository
import com.metmusic.metmusic.core.network.ApiException
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Detalle de playlist editorial: carga `GET /api/playlists/{playlistId}` al
 * init y expone [retry] para el error con reintento.
 */
@HiltViewModel
class PlaylistDetailViewModel @Inject constructor(
    private val playlistRepository: PlaylistRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val playlistId: String = checkNotNull(savedStateHandle.get<String>("playlistId")) {
        "playlistId missing in navigation arguments"
    }

    private val _state = MutableStateFlow(PlaylistDetailUiState())
    val state: StateFlow<PlaylistDetailUiState> = _state.asStateFlow()

    init {
        load()
    }

    /** Reintenta la carga tras un error. */
    fun retry() {
        load()
    }

    private fun load() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            try {
                val playlist = playlistRepository.getPlaylist(playlistId)
                _state.update {
                    it.copy(isLoading = false, playlist = playlist, error = null)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isLoading = false, error = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isLoading = false, error = "No se pudo cargar la playlist")
                }
            }
        }
    }
}
