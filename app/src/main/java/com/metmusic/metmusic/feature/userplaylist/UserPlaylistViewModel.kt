package com.metmusic.metmusic.feature.userplaylist

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.UserPlaylistsRepository
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
 * Estado de una playlist propia (6E-2): carga desde el cache de Room,
 * sincroniza con el backend de forma best-effort y aplica remove/reorder de
 * forma optimista con rollback si el backend falla.
 */
@HiltViewModel
class UserPlaylistViewModel @Inject constructor(
    private val userPlaylistsRepository: UserPlaylistsRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {

    private val playlistId: String = checkNotNull(
        savedStateHandle.get<String>("playlistId"),
    ) { "playlistId missing" }

    private val _state = MutableStateFlow(UserPlaylistUiState())
    val state: StateFlow<UserPlaylistUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch { load() }
    }

    /** Reintenta la carga completa luego de un error. */
    fun retry() {
        viewModelScope.launch { load() }
    }

    /** Alterna el modo edición (drag & drop + remove + agregar). */
    fun toggleEditMode() {
        _state.update { it.copy(isEditMode = !it.isEditMode) }
    }

    /** Quita una canción de la playlist de forma optimista, con rollback. */
    fun removeTrack(trackId: String) {
        val previous = _state.value.tracks
        if (previous.none { track -> track.trackId == trackId }) return
        _state.update {
            it.copy(
                tracks = it.tracks.filterNot { track -> track.trackId == trackId },
                actionError = null,
            )
        }
        viewModelScope.launch {
            try {
                userPlaylistsRepository.removeTrack(playlistId, trackId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        tracks = previous,
                        actionError = "No se pudo quitar la canción",
                    )
                }
            }
        }
    }

    /** Mueve una canción de forma optimista, con rollback si el backend falla. */
    fun moveTrack(fromIndex: Int, toIndex: Int) {
        val previous = _state.value.tracks
        val reordered = previous.toMutableList()
        if (fromIndex !in reordered.indices || toIndex !in reordered.indices) return
        if (fromIndex == toIndex) return
        val moved = reordered.removeAt(fromIndex)
        reordered.add(toIndex, moved)
        _state.update { it.copy(tracks = reordered.toList(), actionError = null) }
        viewModelScope.launch {
            _state.update { it.copy(isSavingOrder = true) }
            try {
                userPlaylistsRepository.reorder(playlistId, reordered.map { track -> track.trackId })
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    it.copy(
                        tracks = previous,
                        isSavingOrder = false,
                        actionError = "No se pudo guardar el orden",
                    )
                }
                return@launch
            }
            _state.update { it.copy(isSavingOrder = false) }
        }
    }

    /** Agrega canciones al backend y recarga la playlist para verlas. */
    fun addTracks(trackIds: List<String>) {
        if (trackIds.isEmpty()) return
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                userPlaylistsRepository.addTracks(playlistId, trackIds)
                load()
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update { it.copy(actionError = e.userMessage) }
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudieron agregar las canciones") }
            }
        }
    }

    /** Dismiss del snackbar de error de acción. */
    fun dismissActionError() {
        _state.update { it.copy(actionError = null) }
    }

    /**
     * Lee el cache primero (respuesta inmediata) y luego refresca contra el
     * backend de forma best-effort: si el refresh falla pero hay cache, la
     * playlist cacheada se mantiene visible.
     */
    private suspend fun load() {
        _state.update { it.copy(isLoading = true, error = null) }
        try {
            val cached = userPlaylistsRepository.getAll()
                .firstOrNull { playlist -> playlist.playlistId == playlistId }
            if (cached != null) {
                _state.update {
                    it.copy(
                        isLoading = false,
                        playlist = cached,
                        tracks = cached.tracks,
                        error = null,
                    )
                }
            }

            var refreshError: Exception? = null
            try {
                userPlaylistsRepository.refresh()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                refreshError = e
            }

            val refreshed = userPlaylistsRepository.getAll()
                .firstOrNull { playlist -> playlist.playlistId == playlistId }
            when {
                refreshed != null -> _state.update {
                    it.copy(
                        isLoading = false,
                        playlist = refreshed,
                        tracks = refreshed.tracks,
                        error = null,
                    )
                }
                cached != null -> _state.update { it.copy(isLoading = false) }
                else -> _state.update {
                    it.copy(isLoading = false, error = refreshError.toLoadErrorMessage())
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: ApiException) {
            _state.update { it.copy(isLoading = false, error = e.userMessage) }
        } catch (e: Exception) {
            _state.update {
                it.copy(isLoading = false, error = "No se pudo cargar la playlist")
            }
        }
    }
}

/** Mensaje de un fallo de refresh cuando no hay nada en cache. */
private fun Throwable?.toLoadErrorMessage(): String = when (this) {
    is ApiException -> userMessage
    null -> "Playlist no encontrada"
    else -> "No se pudo cargar la playlist"
}
