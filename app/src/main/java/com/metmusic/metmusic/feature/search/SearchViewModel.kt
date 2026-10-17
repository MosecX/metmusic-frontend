package com.metmusic.metmusic.feature.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.SearchRepository
import com.metmusic.metmusic.core.model.SearchResults
import com.metmusic.metmusic.core.model.SearchType
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
 * ViewModel de búsqueda.
 *
 * El debounce (300 ms) vive acá, no en la UI: cada cambio de query o de
 * pestaña cancela el request en vuelo y programa uno nuevo. Cancelar no es un
 * error de red y nunca se muestra como tal.
 */
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val repository: SearchRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(SearchState())
    val state: StateFlow<SearchState> = _state.asStateFlow()

    private var searchJob: Job? = null

    fun onQueryChange(value: String) {
        _state.update { it.copy(query = value, error = null) }
        searchJob?.cancel()
        if (value.trim().isEmpty()) {
            _state.update { it.copy(isLoading = false, results = SearchResults.EMPTY) }
            return
        }
        searchJob = viewModelScope.launch {
            delay(300)
            runSearch()
        }
    }

    fun onTypeChange(type: SearchType) {
        _state.update { it.copy(type = type) }
        if (_state.value.query.trim().isNotEmpty()) {
            searchJob?.cancel()
            searchJob = viewModelScope.launch { runSearch() }
        }
    }

    fun retry() {
        if (_state.value.query.trim().isEmpty()) return
        searchJob?.cancel()
        searchJob = viewModelScope.launch { runSearch() }
    }

    private suspend fun runSearch() {
        val current = _state.value
        _state.update { it.copy(isLoading = true, error = null) }
        try {
            val results = repository.search(current.query, current.type)
            _state.update { it.copy(isLoading = false, results = results, error = null) }
        } catch (e: CancellationException) {
            throw e
        } catch (e: ApiException) {
            _state.update { it.copy(isLoading = false, error = e.userMessage) }
        } catch (e: Exception) {
            _state.update { it.copy(isLoading = false, error = "Ocurrió un error inesperado") }
        }
    }
}
