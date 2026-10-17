package com.metmusic.metmusic.feature.userplaylist.addtracks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.SearchRepository
import com.metmusic.metmusic.core.model.SearchType
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Picker de canciones para agregar a una playlist propia (6E-2): búsqueda
 * con debounce de 300 ms contra `/api/search` y selección múltiple local.
 */
@HiltViewModel
class AddTracksViewModel @Inject constructor(
    private val searchRepository: SearchRepository,
) : ViewModel() {

    data class State(
        val query: String = "",
        val isLoading: Boolean = false,
        val results: List<Track> = emptyList(),
        val selected: Set<String> = emptySet(),
        val error: String? = null,
    )

    private val _state = MutableStateFlow(State())
    val state: StateFlow<State> = _state.asStateFlow()

    private var job: Job? = null

    /** Actualiza la query y agenda la búsqueda con debounce. */
    fun onQueryChange(value: String) {
        _state.update { it.copy(query = value, error = null) }
        job?.cancel()
        if (value.trim().isEmpty()) {
            _state.update { it.copy(isLoading = false, results = emptyList()) }
            return
        }
        job = viewModelScope.launch {
            delay(DEBOUNCE_MS)
            runSearch()
        }
    }

    /** Alterna la selección de un track. */
    fun toggleSelection(trackId: String) {
        _state.update {
            val selected = if (trackId in it.selected) {
                it.selected - trackId
            } else {
                it.selected + trackId
            }
            it.copy(selected = selected)
        }
    }

    /** Ids seleccionados, en orden de inserción del set. */
    fun selectedIds(): List<String> = _state.value.selected.toList()

    /** Repite la búsqueda actual sin esperar el debounce (botón de reintento). */
    fun retry() {
        val query = _state.value.query.trim()
        if (query.isEmpty()) return
        job?.cancel()
        job = viewModelScope.launch { runSearch() }
    }

    /** Vuelve al estado inicial al cerrar el picker (query y selección). */
    fun reset() {
        job?.cancel()
        _state.value = State()
    }

    private suspend fun runSearch() {
        _state.update { it.copy(isLoading = true, error = null) }
        try {
            val query = _state.value.query.trim()
            val results = searchRepository.search(
                query = query,
                type = SearchType.TRACKS,
                limit = SEARCH_LIMIT,
            )
            _state.update {
                it.copy(isLoading = false, results = results.tracks, error = null)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: ApiException) {
            _state.update { it.copy(isLoading = false, error = e.userMessage) }
        } catch (e: Exception) {
            _state.update {
                it.copy(isLoading = false, error = "No se pudo buscar")
            }
        }
    }

    private companion object {
        /** Ventana de debounce del campo de búsqueda. */
        const val DEBOUNCE_MS = 300L

        /** Tope de resultados que trae el picker. */
        const val SEARCH_LIMIT = 30
    }
}
