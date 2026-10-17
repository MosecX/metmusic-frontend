package com.metmusic.metmusic.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.ExploreRepository
import com.metmusic.metmusic.core.data.HistoryRepository
import com.metmusic.metmusic.core.network.ApiException
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Límites de la Home (contrato del MASTER BUILD, iguales a Flutter). */
private const val NEW_RELEASES_LIMIT = 20
private const val CHARTS_LIMIT = 20
private const val RECENT_LIMIT = 10

/**
 * Estado de la Home: carga explore + novedades + charts + historial
 * reciente en paralelo, con resolución de errores por fuente.
 */
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val exploreRepository: ExploreRepository,
    private val historyRepository: HistoryRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeUiState())
    val state: StateFlow<HomeUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch { load() }
    }

    /** Cambia el mood de Explore y recarga solo esa fuente. */
    fun onMoodSelected(mood: String?) {
        if (mood == _state.value.selectedMood) return
        _state.update { it.copy(selectedMood = mood, error = null) }
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val explore = runCatchingNonCancel { exploreRepository.getHome(mood = mood) }
            _state.update { current ->
                explore.fold(
                    onSuccess = { home ->
                        current.copy(isLoading = false, explore = home, offline = false)
                    },
                    onFailure = { error ->
                        current.copy(isLoading = false, error = error.toUserMessage())
                    },
                )
            }
        }
    }

    /** Pull to refresh: recarga las cuatro fuentes conservando el mood. */
    fun refresh() {
        viewModelScope.launch { load(isRefresh = true) }
    }

    /** Reintento del error state: mismo camino que la carga inicial. */
    fun retry() {
        viewModelScope.launch { load() }
    }

    private suspend fun load(isRefresh: Boolean = false) {
        _state.update {
            it.copy(
                isLoading = !isRefresh,
                isRefreshing = isRefresh,
                error = null,
            )
        }
        val mood = _state.value.selectedMood
        coroutineScope {
            val exploreDeferred = async {
                runCatchingNonCancel { exploreRepository.getHome(mood = mood) }
            }
            val newReleasesDeferred = async {
                runCatchingNonCancel { exploreRepository.getNewReleases(limit = NEW_RELEASES_LIMIT) }
            }
            val chartsDeferred = async {
                runCatchingNonCancel { exploreRepository.getCharts(limit = CHARTS_LIMIT) }
            }
            val recentDeferred = async {
                runCatchingNonCancel { historyRepository.recentDistinct(limit = RECENT_LIMIT) }
            }

            val explore = exploreDeferred.await()
            val newReleases = newReleasesDeferred.await()
            val charts = chartsDeferred.await()
            val recent = recentDeferred.await()

            _state.update { current ->
                val recentValue = recent.getOrNull()
                val updated = current.copy(
                    isLoading = false,
                    isRefreshing = false,
                    explore = explore.getOrNull() ?: current.explore,
                    newReleases = newReleases.getOrNull() ?: current.newReleases,
                    charts = charts.getOrNull() ?: current.charts,
                    recent = recentValue ?: current.recent,
                    offline = explore.isFailure && !recentValue.isNullOrEmpty(),
                )
                updated.copy(
                    error = if (updated.isEmpty) {
                        firstFailure(explore, newReleases, charts, recent)?.toUserMessage()
                    } else {
                        null
                    },
                )
            }
        }
    }

    /** `Result` a prueba de cancelaciones: nunca traga [CancellationException]. */
    private suspend fun <T> runCatchingNonCancel(block: suspend () -> T): Result<T> = try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Throwable) {
        Result.failure(e)
    }
}

/** Primer error disponible para el error state (solo si no hay contenido). */
private fun firstFailure(vararg results: Result<*>): Throwable? =
    results.firstNotNullOfOrNull { it.exceptionOrNull() }

/** Mensaje de usuario del error: el de [ApiException] o el fallback genérico. */
private fun Throwable.toUserMessage(): String = (this as? ApiException)?.userMessage
    ?: "Ocurrió un error inesperado"
