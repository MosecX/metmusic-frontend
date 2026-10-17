package com.metmusic.metmusic.feature.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.FavoritesRepository
import com.metmusic.metmusic.core.data.HistoryRepository
import com.metmusic.metmusic.core.data.MixFavoritesRepository
import com.metmusic.metmusic.core.data.UserPlaylistsRepository
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

/**
 * Estado de la Biblioteca: lee las cuatro listas locales (playlists,
 * favoritos, mixes e historial) y aplica las acciones CRUD actualizando el
 * estado en memoria sin refetch.
 */
@HiltViewModel
class LibraryViewModel @Inject constructor(
    private val userPlaylistsRepository: UserPlaylistsRepository,
    private val favoritesRepository: FavoritesRepository,
    private val mixFavoritesRepository: MixFavoritesRepository,
    private val historyRepository: HistoryRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(LibraryUiState())
    val state: StateFlow<LibraryUiState> = _state.asStateFlow()

    init {
        viewModelScope.launch { load() }
    }

    /** Cambia de pestaña y descarta el error de acción pendiente. */
    fun selectTab(tab: LibraryTab) {
        if (tab == _state.value.selectedTab) return
        _state.update { it.copy(selectedTab = tab, actionError = null) }
    }

    /** Recarga las cuatro listas locales (sin gesto de pull-to-refresh en 6C). */
    fun refresh() {
        viewModelScope.launch { load(isRefresh = true) }
    }

    /** Reintenta la carga luego de un error. */
    fun retry() {
        viewModelScope.launch { load() }
    }

    /** Dismiss del snackbar de error de acción. */
    fun dismissActionError() {
        _state.update { it.copy(actionError = null) }
    }

    fun createPlaylist(name: String, description: String?, coverUrl: String?) {
        val trimmedName = name.trim()
        if (trimmedName.isEmpty()) return
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                val created = userPlaylistsRepository.create(
                    name = trimmedName,
                    description = description?.trim()?.ifEmpty { null },
                    coverUrl = coverUrl?.trim()?.ifEmpty { null },
                )
                _state.update {
                    it.copy(
                        playlists = (listOf(created) + it.playlists)
                            .distinctBy { playlist -> playlist.playlistId },
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update { it.copy(actionError = e.userMessage) }
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo crear la playlist") }
            }
        }
    }

    fun renamePlaylist(id: String, newName: String) {
        val trimmedName = newName.trim()
        if (trimmedName.isEmpty()) return
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                val updated = userPlaylistsRepository.rename(id, trimmedName)
                _state.update {
                    it.copy(
                        playlists = it.playlists.map { playlist ->
                            if (playlist.playlistId == id) updated else playlist
                        },
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update { it.copy(actionError = e.userMessage) }
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo renombrar la playlist") }
            }
        }
    }

    fun deletePlaylist(id: String) {
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                userPlaylistsRepository.delete(id)
                _state.update {
                    it.copy(playlists = it.playlists.filter { playlist -> playlist.playlistId != id })
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update { it.copy(actionError = e.userMessage) }
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo borrar la playlist") }
            }
        }
    }

    fun removeFavorite(trackId: String) {
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                favoritesRepository.remove(trackId)
                _state.update {
                    it.copy(favorites = it.favorites.filter { track -> track.trackId != trackId })
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update { it.copy(actionError = e.userMessage) }
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo quitar el favorito") }
            }
        }
    }

    fun removeMix(trackId: String) {
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                mixFavoritesRepository.remove(trackId)
                _state.update {
                    it.copy(mixes = it.mixes.filter { savedMix -> savedMix.trackId != trackId })
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo borrar el mix") }
            }
        }
    }

    fun clearHistory() {
        viewModelScope.launch {
            _state.update { it.copy(actionError = null) }
            try {
                historyRepository.clear()
                _state.update { it.copy(history = emptyList()) }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update { it.copy(actionError = "No se pudo limpiar el historial") }
            }
        }
    }

    /**
     * Lee las cuatro listas de Room en paralelo. Sin red: los `getAll` de
     * los repositorios leen del cache local (la sincronización con el
     * backend la hacen las acciones CRUD).
     */
    private suspend fun load(isRefresh: Boolean = false) {
        _state.update {
            it.copy(
                isLoading = !isRefresh,
                isRefreshing = isRefresh,
                error = null,
            )
        }
        coroutineScope {
            val playlistsDeferred = async {
                runCatchingNonCancel { userPlaylistsRepository.getAll() }
            }
            val favoritesDeferred = async {
                runCatchingNonCancel { favoritesRepository.getAll() }
            }
            val mixesDeferred = async {
                runCatchingNonCancel { mixFavoritesRepository.getAll() }
            }
            val historyDeferred = async {
                runCatchingNonCancel { historyRepository.getAll(limit = HISTORY_LIMIT) }
            }

            val playlists = playlistsDeferred.await()
            val favorites = favoritesDeferred.await()
            val mixes = mixesDeferred.await()
            val history = historyDeferred.await()

            _state.update { current ->
                val allFailed = playlists.isFailure && favorites.isFailure &&
                    mixes.isFailure && history.isFailure
                current.copy(
                    isLoading = false,
                    isRefreshing = false,
                    playlists = playlists.getOrNull() ?: current.playlists,
                    favorites = favorites.getOrNull() ?: current.favorites,
                    mixes = mixes.getOrNull() ?: current.mixes,
                    history = history.getOrNull() ?: current.history,
                    error = if (allFailed) {
                        firstFailureMessage(
                            playlists.exceptionOrNull(),
                            favorites.exceptionOrNull(),
                            mixes.exceptionOrNull(),
                            history.exceptionOrNull(),
                        )
                    } else {
                        null
                    },
                )
            }
        }
    }

    private suspend fun <T> runCatchingNonCancel(block: suspend () -> T): Result<T> = try {
        Result.success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Throwable) {
        Result.failure(e)
    }

    private companion object {
        /** El historial completo de la Biblioteca (Home usa un límite menor). */
        const val HISTORY_LIMIT = 200
    }
}

/** Mensaje de usuario del error: el de [ApiException] o el fallback genérico. */
private fun Throwable.toUserMessage(): String = (this as? ApiException)?.userMessage
    ?: "Ocurrió un error inesperado"

/** Primer mensaje de fallo entre las cuatro lecturas (cuando todas fallaron). */
private fun firstFailureMessage(
    playlists: Throwable?,
    favorites: Throwable?,
    mixes: Throwable?,
    history: Throwable?,
): String? = (playlists ?: favorites ?: mixes ?: history)?.toUserMessage()
