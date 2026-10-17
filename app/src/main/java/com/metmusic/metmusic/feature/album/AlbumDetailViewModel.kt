package com.metmusic.metmusic.feature.album

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.AlbumRepository
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
 * Detalle de álbum: carga `GET /api/albums/{albumId}` al init y expone
 * [retry] para el error con reintento.
 */
@HiltViewModel
class AlbumDetailViewModel @Inject constructor(
    private val albumRepository: AlbumRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val albumId: String = checkNotNull(savedStateHandle.get<String>("albumId")) {
        "albumId missing in navigation arguments"
    }

    private val _state = MutableStateFlow(AlbumDetailUiState())
    val state: StateFlow<AlbumDetailUiState> = _state.asStateFlow()

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
                val album = albumRepository.getAlbum(albumId)
                _state.update {
                    it.copy(isLoading = false, album = album, error = null)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isLoading = false, error = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isLoading = false, error = "No se pudo cargar el álbum")
                }
            }
        }
    }
}
