package com.metmusic.metmusic.feature.player

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.google.common.util.concurrent.MoreExecutors
import com.metmusic.metmusic.core.data.FavoritesRepository
import com.metmusic.metmusic.core.data.SettingsRepository
import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.StreamInfo
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.ui.util.NotificationPermission
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.feature.player.service.PlaybackService
import dagger.hilt.android.qualifiers.ApplicationContext
import java.time.Duration
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private const val TAG = "PlayerConnection"
private const val EXTRAS_TRACK_JSON = "trackJson"
private const val CONTROLLER_CONNECT_TIMEOUT_MS = 10_000L
private const val POLL_INTERVAL_MS = 500L
private const val RESTART_TRACK_MS = 3_000L

/**
 * Puente de la app con [PlaybackService]: conecta el `MediaController` de
 * Media3, publica [PlayerUiState], expone las acciones de reproducción y el
 * favorito del track activo ([isFavorite]).
 *
 * Shuffle y repeat se manejan sobre el controller (Media3 nativo) y se
 * persisten en [SettingsRepository] para restaurarlos al reconectar, así que
 * [QueueManager] queda como espejo de metadata. El `StreamInfo` del track
 * activo se guarda por id y vive en el estado.
 */
@Singleton
class PlayerConnection @Inject constructor(
    @ApplicationContext private val context: Context,
    private val streamResolver: StreamResolver,
    private val queueManager: QueueManager,
    private val historyReporter: HistoryReporter,
    private val settingsRepository: SettingsRepository,
    private val favoritesRepository: FavoritesRepository,
) {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    private val controllerFuture = MediaController.Builder(
        context,
        SessionToken(context, ComponentName(context, PlaybackService::class.java)),
    ).buildAsync()

    private var controller: MediaController? = null
    private var pollJob: Job? = null
    private val streamsByTrackId = mutableMapOf<String, StreamInfo>()

    private val _state = MutableStateFlow(PlayerUiState.EMPTY)
    val state: StateFlow<PlayerUiState> = _state.asStateFlow()

    private val _isFavorite = MutableStateFlow(false)

    /** Favorito del track activo (Room es la fuente de verdad). */
    val isFavorite: StateFlow<Boolean> = _isFavorite.asStateFlow()

    /** trackId cuyo favorito refleja [isFavorite]; null sin track. */
    private var favoriteTrackId: String? = null

    /** Incrementa en cada consulta/toggle para descartar resultados viejos. */
    private var favoriteRevision = 0

    private val listener = object : Player.Listener {
        override fun onMediaItemTransition(mediaItem: MediaItem?, reason: Int) {
            syncFromController()
            historyReporter.onMediaItemTransition(mediaItem, reason)
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            syncFromController()
            if (!isPlaying) {
                // Último tick al pausar/terminar: captura la posición final.
                controller?.let { historyReporter.onPositionTick(it.currentPosition, it.duration) }
            }
        }

        override fun onPlaybackStateChanged(playbackState: Int) {
            syncFromController()
        }

        override fun onPlayerError(error: PlaybackException) {
            _state.update { it.copy(error = error.message) }
        }

        override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {
            syncFromController()
        }

        override fun onRepeatModeChanged(repeatMode: Int) {
            syncFromController()
        }
    }

    init {
        controllerFuture.addListener(
            {
                val connected = try {
                    controllerFuture.get()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.e(TAG, "MediaController connection failed", e)
                    null
                }
                scope.launch { onControllerReady(connected) }
            },
            MoreExecutors.directExecutor(),
        )
    }

    // --- Acciones públicas (fire-and-forget) ---

    /** Reemplaza la cola y arranca desde [startIndex]. */
    fun playQueue(tracks: List<Track>, startIndex: Int) {
        scope.launch { doPlayQueue(tracks, startIndex) }
    }

    /** Reproduce una única pista. */
    fun playSingle(track: Track) = playQueue(listOf(track), 0)

    /** Alterna play/pausa. */
    fun togglePlayPause() {
        scope.launch {
            val c = awaitController() ?: return@launch
            if (c.isPlaying) c.pause() else c.play()
        }
    }

    /** Arranca la reproducción. */
    fun play() {
        scope.launch { awaitController()?.play() }
    }

    /** Pausa la reproducción. */
    fun pause() {
        scope.launch { awaitController()?.pause() }
    }

    /** Salta a [positionMs] de la pista actual. */
    fun seekTo(positionMs: Long) {
        scope.launch { awaitController()?.seekTo(positionMs.coerceAtLeast(0L)) }
    }

    /** Pasa a la pista siguiente si existe. */
    fun next() {
        scope.launch {
            val c = awaitController() ?: return@launch
            if (c.hasNextMediaItem()) c.seekToNextMediaItem()
        }
    }

    /** Pista anterior; tras 3 s de reproducción, reinicia la pista actual. */
    fun previous() {
        scope.launch {
            val c = awaitController() ?: return@launch
            if (c.currentPosition > RESTART_TRACK_MS) {
                c.seekTo(0L)
                return@launch
            }
            if (c.hasPreviousMediaItem()) c.seekToPreviousMediaItem() else c.seekTo(0L)
        }
    }

    /** Alterna shuffle sobre el controller (Media3 nativo) y lo persiste. */
    fun toggleShuffle() {
        scope.launch {
            val c = awaitController() ?: return@launch
            c.shuffleModeEnabled = !c.shuffleModeEnabled
            try {
                settingsRepository.setShuffle(c.shuffleModeEnabled)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, "No se pudo persistir shuffle: ${e.message}")
            }
        }
    }

    /** Cicla repeat OFF → ALL → ONE sobre el controller y lo persiste. */
    fun cycleRepeat() {
        scope.launch {
            val c = awaitController() ?: return@launch
            val next = when (c.repeatMode) {
                Player.REPEAT_MODE_OFF -> Player.REPEAT_MODE_ALL
                Player.REPEAT_MODE_ALL -> Player.REPEAT_MODE_ONE
                else -> Player.REPEAT_MODE_OFF
            }
            c.repeatMode = next
            val persisted = when (next) {
                Player.REPEAT_MODE_ONE -> RepeatMode.ONE
                Player.REPEAT_MODE_ALL -> RepeatMode.ALL
                else -> RepeatMode.OFF
            }
            try {
                settingsRepository.setRepeatMode(persisted)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, "No se pudo persistir repeat: ${e.message}")
            }
        }
    }

    /** Alterna el favorito del track activo; si no hay track, no hace nada. */
    fun toggleFavorite() {
        scope.launch {
            val track = _state.value.track ?: return@launch
            try {
                val newState = favoritesRepository.toggle(track)
                favoriteTrackId = track.trackId
                favoriteRevision++
                _isFavorite.value = newState
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, "toggleFavorite failed: ${e.message}")
            }
        }
    }

    /** True si el sistema aún exige pedir POST_NOTIFICATIONS (consulta para la UI). */
    fun requiresNotificationPermission(context: Context): Boolean =
        NotificationPermission.shouldRequest(context)

    /** Detiene la reproducción y vacía la cola. */
    fun clearQueue() {
        scope.launch {
            awaitController()?.run {
                stop()
                clearMediaItems()
            }
            queueManager.clear()
            streamsByTrackId.clear()
            refreshFavorite(null)
            _state.value = PlayerUiState.EMPTY
        }
    }

    // --- Internos ---

    private suspend fun doPlayQueue(tracks: List<Track>, startIndex: Int) {
        if (tracks.isEmpty()) return
        val c = awaitController() ?: return
        queueManager.setQueue(tracks, startIndex)
        _state.update {
            it.copy(
                isBuffering = true,
                processingState = PlayerUiState.ProcessingState.LOADING,
                error = null,
                queue = tracks,
                currentIndex = queueManager.currentIndex.value,
            )
        }
        val entries = tracks.mapNotNull { track -> resolveEntry(track) }
        if (entries.isEmpty()) {
            _state.update { it.copy(error = "No se pudo preparar la pista") }
            return
        }
        val index = startIndex.coerceIn(0, entries.lastIndex)
        c.setMediaItems(entries.map { it.item }, index, 0L)
        _state.update { it.copy(streamInfo = entries[index].stream) }
        c.prepare()
        c.play()
    }

    private suspend fun resolveEntry(track: Track): ResolvedEntry? {
        val stream = try {
            streamResolver.resolve(track.trackId)
        } catch (e: CancellationException) {
            throw e
        } catch (e: ApiException) {
            _state.update { it.copy(error = e.userMessage) }
            return null
        } catch (e: Exception) {
            _state.update { it.copy(error = "No se pudo resolver la URL de la pista") }
            return null
        }
        streamsByTrackId[track.trackId] = stream
        return ResolvedEntry(item = buildMediaItem(track, stream), stream = stream)
    }

    private fun buildMediaItem(track: Track, stream: StreamInfo): MediaItem {
        val extras = Bundle().apply {
            putString(EXTRAS_TRACK_JSON, JsonParse.encode(track.toJson()))
        }
        return MediaItem.Builder()
            .setMediaId(track.trackId)
            .setUri(Uri.parse(stream.url))
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setTitle(track.displayTitle)
                    .setArtist(track.artist)
                    .setAlbumTitle(track.album)
                    .setArtworkUri(track.thumbnailUrl.takeIf { it.isNotEmpty() }?.let(Uri::parse))
                    .setExtras(extras)
                    .build(),
            )
            .build()
    }

    private fun syncFromController() {
        val c = controller ?: return
        val item = c.currentMediaItem
        val currentIndex = c.currentMediaItemIndex
        val track = item?.let { mediaItem -> mediaItemToTrack(mediaItem) }
        val processing = when (c.playbackState) {
            Player.STATE_IDLE -> PlayerUiState.ProcessingState.IDLE
            Player.STATE_BUFFERING -> PlayerUiState.ProcessingState.BUFFERING
            Player.STATE_READY -> PlayerUiState.ProcessingState.READY
            Player.STATE_ENDED -> PlayerUiState.ProcessingState.ENDED
            else -> PlayerUiState.ProcessingState.IDLE
        }
        val repeat = when (c.repeatMode) {
            Player.REPEAT_MODE_ONE -> RepeatMode.ONE
            Player.REPEAT_MODE_ALL -> RepeatMode.ALL
            else -> RepeatMode.OFF
        }
        _state.update {
            it.copy(
                mediaId = item?.mediaId,
                track = track,
                isPlaying = c.isPlaying,
                isBuffering = c.playbackState == Player.STATE_BUFFERING,
                processingState = processing,
                duration = Duration.ofMillis(c.duration.coerceAtLeast(0L)),
                buffered = Duration.ofMillis(c.bufferedPosition.coerceAtLeast(0L)),
                queue = queueManager.queue.value,
                currentIndex = currentIndex,
                shuffleEnabled = c.shuffleModeEnabled,
                repeatMode = repeat,
                streamInfo = item?.mediaId?.let { streamsByTrackId[it] },
            )
        }
        queueManager.setCurrentIndex(currentIndex)
        refreshFavorite(item?.mediaId)
    }

    private fun syncPositions(c: MediaController) {
        _state.update {
            it.copy(
                position = Duration.ofMillis(c.currentPosition.coerceAtLeast(0L)),
                buffered = Duration.ofMillis(c.bufferedPosition.coerceAtLeast(0L)),
            )
        }
    }

    private fun mediaItemToTrack(item: MediaItem): Track? {
        val json = item.mediaMetadata.extras?.getString(EXTRAS_TRACK_JSON) ?: return null
        return try {
            JsonParse.parse(json)?.let { Track.fromJson(it) }
        } catch (e: Exception) {
            null
        }
    }

    private fun startPolling() {
        pollJob?.cancel()
        pollJob = scope.launch {
            while (isActive) {
                val c = controller
                if (c != null && c.isPlaying) {
                    syncPositions(c)
                    historyReporter.onPositionTick(c.currentPosition, c.duration)
                }
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    private fun onControllerReady(connected: MediaController?) {
        if (connected == null) return
        if (controller !== connected) {
            controller = connected
            connected.addListener(listener)
            applyPersistedPlaybackSettings(connected)
        }
        syncFromController()
        startPolling()
    }

    /** Aplica shuffle/repeat guardados al controller recién conectado. */
    private fun applyPersistedPlaybackSettings(c: MediaController) {
        scope.launch {
            val settings = try {
                settingsRepository.settings.first()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, "applyPersistedPlaybackSettings failed: ${e.message}")
                return@launch
            }
            c.shuffleModeEnabled = settings.shuffle
            c.repeatMode = when (settings.repeatMode) {
                RepeatMode.OFF -> Player.REPEAT_MODE_OFF
                RepeatMode.ALL -> Player.REPEAT_MODE_ALL
                RepeatMode.ONE -> Player.REPEAT_MODE_ONE
            }
        }
    }

    /**
     * Refresca [isFavorite] cuando cambia el track activo; solo aplica el
     * resultado si el track y la revisión siguen vigentes (skips rápidos y
     * toggles descartan consultas viejas).
     */
    private fun refreshFavorite(trackId: String?) {
        if (trackId == favoriteTrackId) return
        favoriteTrackId = trackId
        val revision = ++favoriteRevision
        if (trackId == null) {
            _isFavorite.value = false
            return
        }
        scope.launch {
            val favorite = try {
                favoritesRepository.isFavorite(trackId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.d(TAG, "isFavorite failed: ${e.message}")
                false
            }
            if (revision == favoriteRevision && favoriteTrackId == trackId) {
                _isFavorite.value = favorite
            }
        }
    }

    private suspend fun awaitController(): MediaController? {
        controller?.let { return it }
        return try {
            val connected = withContext(Dispatchers.IO) {
                controllerFuture.get(CONTROLLER_CONNECT_TIMEOUT_MS, TimeUnit.MILLISECONDS)
            }
            onControllerReady(connected)
            connected
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e(TAG, "awaitController failed", e)
            null
        }
    }

    /** MediaItem listo para el player + el stream que lo resolvió. */
    private data class ResolvedEntry(val item: MediaItem, val stream: StreamInfo)
}
