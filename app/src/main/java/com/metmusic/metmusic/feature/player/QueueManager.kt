package com.metmusic.metmusic.feature.player

import com.metmusic.metmusic.core.model.Track
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Espejo de metadata de la cola del reproductor.
 *
 * No es la fuente de verdad del orden (Media3 lo es): mantiene la lista de
 * [Track] completa para la UI y el índice actual, sincronizados por
 * [PlayerConnection] desde los eventos del controller. Shuffle y repeat se
 * manejan sobre el controller (Media3 nativo), no acá.
 */
@Singleton
class QueueManager @Inject constructor() {

    private val _queue = MutableStateFlow<List<Track>>(emptyList())
    val queue: StateFlow<List<Track>> = _queue.asStateFlow()

    private val _currentIndex = MutableStateFlow(-1)
    val currentIndex: StateFlow<Int> = _currentIndex.asStateFlow()

    /** Reemplaza la cola y fija el índice actual (clampeado al rango). */
    fun setQueue(tracks: List<Track>, startIndex: Int) {
        _queue.value = tracks
        _currentIndex.value = startIndex.coerceIn(0, (tracks.size - 1).coerceAtLeast(0))
    }

    /** Mueve el índice actual si cae dentro de la cola. */
    fun setCurrentIndex(index: Int) {
        if (index < 0 || index >= _queue.value.size) return
        _currentIndex.value = index
    }

    /** Agrega una pista al final, o justo después de la actual si [next]. */
    fun addTrack(track: Track, next: Boolean = false) {
        val current = _queue.value.toMutableList()
        if (next) {
            val insertAt = (_currentIndex.value + 1).coerceIn(0, current.size)
            current.add(insertAt, track)
        } else {
            current.add(track)
        }
        _queue.value = current
    }

    /**
     * Quita la pista en [index]. Devuelve `true` si la quitada era la actual;
     * en ese caso el índice queda apuntando a un vecino.
     */
    fun removeAt(index: Int): Boolean {
        val current = _queue.value.toMutableList()
        if (index < 0 || index >= current.size) return false
        val wasCurrent = index == _currentIndex.value
        current.removeAt(index)
        _queue.value = current
        if (current.isEmpty()) {
            _currentIndex.value = -1
        } else if (wasCurrent) {
            _currentIndex.value = _currentIndex.value.coerceIn(0, current.lastIndex)
        } else if (index < _currentIndex.value) {
            _currentIndex.value -= 1
        }
        return wasCurrent
    }

    /** Mueve la pista de [from] a [to]; el índice sigue a la pista actual. */
    fun move(from: Int, to: Int) {
        val current = _queue.value.toMutableList()
        if (from < 0 || from >= current.size) return
        val target = to.coerceIn(0, current.lastIndex)
        val moved = current.removeAt(from)
        current.add(target, moved)
        val currentIndexAfter = when {
            _currentIndex.value == from -> target
            from < _currentIndex.value && target >= _currentIndex.value -> _currentIndex.value - 1
            from > _currentIndex.value && target <= _currentIndex.value -> _currentIndex.value + 1
            else -> _currentIndex.value
        }
        _queue.value = current
        _currentIndex.value = currentIndexAfter
    }

    /** Vacía la cola y resetea el índice. */
    fun clear() {
        _queue.value = emptyList()
        _currentIndex.value = -1
    }

    /** Pista actual, o `null` si la cola está vacía. */
    fun current(): Track? = _queue.value.getOrNull(_currentIndex.value)
}
