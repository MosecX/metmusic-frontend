package com.metmusic.metmusic.feature.mix

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.MixFavoritesRepository
import com.metmusic.metmusic.core.data.RadioRepository
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
 * Pantalla de estación radial: un track semilla genera una estación completa
 * (radio) con [RadioRepository]. El estado, el save/remove del mix y el retry
 * pertenecen aquí; la UI solo presenta [MixUiState] y delega las acciones.
 */
@HiltViewModel
class MixViewModel @Inject constructor(
    private val radioRepository: RadioRepository,
    private val mixFavoritesRepository: MixFavoritesRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val trackId: String = checkNotNull(
        savedStateHandle.get<String>("trackId"),
    ) { "trackId missing" }

    private val _state = MutableStateFlow(MixUiState())
    val state: StateFlow<MixUiState> = _state.asStateFlow()

    init {
        load()
    }

    fun retry() {
        viewModelScope.launch {
            load()
        }
    }

    /**
     * Alterna el mix sobre el repo local y actualiza el estado.
     *
     * La UI no dispara este callback dos veces seguidas; el repo
     * [toggle] es atómico y devuelve el nuevo estado.
     */
    fun toggleFavorite() {
        val current = _state.value
        val station = current.station ?: return
        if (current.isTogglingFavorite) return

        viewModelScope.launch {
            _state.update { it.copy(isTogglingFavorite = true) }
            try {
                val nowFavorite = mixFavoritesRepository.toggle(
                    trackId = trackId,
                    mix = station.mix,
                )
                _state.update {
                    it.copy(isFavorite = nowFavorite, isTogglingFavorite = false)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        isTogglingFavorite = false,
                        actionError = "No se pudo actualizar el mix",
                    )
                }
            }
        }
    }

    /**
     * Cierra el snackbar de error de acción. Se llama desde la UI después de
     * mostrarlo.
     */
    fun dismissActionError() {
        _state.update { it.copy(actionError = null) }
    }

    private fun load() {
        viewModelScope.launch {
            _state.update {
                it.copy(isLoading = true, error = null, isNotFound = false)
            }
            try {
                val station = radioRepository.getRadio(trackId)
                if (station == null) {
                    _state.update {
                        it.copy(isLoading = false, isNotFound = true)
                    }
                    return@launch
                }
                val alreadyFavorite = mixFavoritesRepository.isFavorite(trackId)
                _state.update {
                    it.copy(
                        isLoading = false,
                        station = station,
                        isFavorite = alreadyFavorite,
                        isNotFound = false,
                        error = null,
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isLoading = false, error = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isLoading = false, error = "No se pudo cargar la estación")
                }
            }
        }
    }
}
