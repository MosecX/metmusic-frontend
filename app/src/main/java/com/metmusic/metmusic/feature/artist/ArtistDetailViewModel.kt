package com.metmusic.metmusic.feature.artist

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.ArtistRepository
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
 * Detalle de artista: carga `GET /api/artists/{artistId}` al init y expone
 * [retry] para el error con reintento.
 */
@HiltViewModel
class ArtistDetailViewModel @Inject constructor(
    private val artistRepository: ArtistRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val artistId: String = checkNotNull(savedStateHandle.get<String>("artistId")) {
        "artistId missing in navigation arguments"
    }

    private val _state = MutableStateFlow(ArtistDetailUiState())
    val state: StateFlow<ArtistDetailUiState> = _state.asStateFlow()

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
                val artist = artistRepository.getArtist(artistId)
                _state.update {
                    it.copy(isLoading = false, artist = artist, error = null)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isLoading = false, error = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isLoading = false, error = "No se pudo cargar el artista")
                }
            }
        }
    }
}
