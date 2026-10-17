import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/stream_info.dart';
import '../../../core/models/track.dart';
import '../models/queue_state.dart';
import 'audio_player_service.dart';
import 'queue_manager.dart';

/// Resuelve la URL de stream de un track.
///
/// Se inyecta para desacoplar el [MetMusicAudioHandler] de Riverpod y de los
/// services HTTP.
typedef StreamResolver = Future<StreamInfo> Function(Track track);

/// AudioHandler de `audio_service` que orquesta just_audio y la cola.
///
/// Publica `playbackState`, `mediaItem` y `queue` (notificación del sistema,
/// Bluetooth, Android Auto) y expone streams extra para la UI
/// (stream resuelto, estado de carga y errores).
class MetMusicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  MetMusicAudioHandler({
    required StreamResolver resolveStream,
    AudioPlayerService? player,
    QueueManager? queue,
  })  : _resolveStream = resolveStream,
        _player = player ?? AudioPlayerService(),
        _queue = queue ?? QueueManager() {
    _init();
  }

  final StreamResolver _resolveStream;
  final AudioPlayerService _player;
  final QueueManager _queue;

  final StreamController<StreamInfo?> _streamController =
      StreamController<StreamInfo?>.broadcast();
  final StreamController<bool> _loadingController =
      StreamController<bool>.broadcast();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();

  StreamSubscription<QueueState>? _queueSub;
  StreamSubscription<PlayerState>? _playerSub;

  StreamInfo? _currentStream;
  bool _loading = false;
  int _loadingGeneration = 0;

  /// Track que ya está siendo cargado por una llamada explícita.
  ///
  /// Evita que `_onQueueChanged` dispare una segunda resolución del stream
  /// cuando el cambio de pista lo provocó `playQueue` / `jumpTo` / `skipToNext`.
  String? _plannedTrackId;

  // ------------------------------------------------------------------ Público

  AudioPlayerService get playerService => _player;
  QueueManager get queueManager => _queue;

  /// URL resuelta del track actual (para el badge de calidad y el canvas).
  Stream<StreamInfo?> get streamInfoStream => _streamController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<Object> get errorStream => _errorController.stream;

  StreamInfo? get currentStream => _currentStream;
  bool get isLoading => _loading;
  Track? get currentTrack => _queue.current;
  QueueState get queueState => _queue.state;

  // -------------------------------------------------------------- Arranque

  void _init() {
    _queueSub = _queue.stream.listen(_onQueueChanged);
    _playerSub = _player.playerStateStream.listen((state) {
      _broadcastState();
      if (state.processingState == ProcessingState.completed) {
        _handleCompletion();
      }
    });
    // El playbackState inicial debe reflejar la cola vacía.
    _broadcastState();
  }

  // ------------------------------------------------------------- Reproducción

  /// Reproduce una cola completa a partir de [startIndex].
  Future<void> playQueue(
    List<Track> tracks, {
    int startIndex = 0,
    bool autoplay = true,
  }) async {
    _queue.setQueue(tracks, startIndex: startIndex);
    final current = _queue.current;

    // Si el track ya está cargado (tocar play sobre el actual), evitar
    // volver a resolver el stream: sólo reanudar.
    if (current != null &&
        current.trackId == mediaItem.value?.id &&
        _player.hasSource) {
      _plannedTrackId = current.trackId;
      if (autoplay) await _player.play();
      _broadcastState();
      return;
    }

    await _loadCurrent(autoplay: autoplay);
  }

  /// Reproduce un único track (tap en resultados de búsqueda, etc.).
  Future<void> playSingle(Track track, {bool autoplay = true}) =>
      playQueue([track], startIndex: 0, autoplay: autoplay);

  /// Reproduce un track ya presente en la cola por índice.
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.tracks.length) return;
    final isSame = index == _queue.currentIndex;
    _queue.setCurrentIndex(index);
    if (isSame && mediaItem.value?.id == _queue.current?.trackId) {
      await play();
      return;
    }
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> play() async {
    if (!_player.hasSource) {
      await _loadCurrent(autoplay: true);
      return;
    }
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    final index = _queue.nextIndex(manual: true);
    if (index == null) return;
    _queue.setCurrentIndex(index);
    await _loadCurrent(autoplay: true);
  }

  @override
  Future<void> skipToPrevious() async {
    // Si pasaron más de 3 s, "anterior" reinicia el track actual.
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    final index = _queue.previousIndex();
    if (index == null) {
      await _player.seek(Duration.zero);
      return;
    }
    _queue.setCurrentIndex(index);
    await _loadCurrent(autoplay: true);
  }

  // ------------------------------------------------------------- Cola / modos

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    final mode = switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group =>
        LoopMode.all,
      AudioServiceRepeatMode.none => LoopMode.off,
    };
    _queue.setRepeat(mode);
    await _player.setLoopMode(mode);
    _broadcastState();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _queue.setShuffle(shuffleMode == AudioServiceShuffleMode.all);
    _broadcastState();
  }

  /// Alterna shuffle desde la UI.
  Future<void> toggleShuffle() async {
    await setShuffleMode(
      _queue.shuffle
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all,
    );
  }

  /// Cicla off → all → one desde la UI.
  Future<void> cycleRepeat() async {
    final next = switch (_queue.repeat) {
      LoopMode.off => AudioServiceRepeatMode.all,
      LoopMode.all => AudioServiceRepeatMode.one,
      LoopMode.one => AudioServiceRepeatMode.none,
    };
    await setRepeatMode(next);
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final track = trackFromMediaItem(mediaItem);
    if (track == null) return;
    _queue.addTrack(track);
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    _queue.addTracks(
      mediaItems.map(trackFromMediaItem).whereType<Track>().toList(),
    );
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = _queue.tracks.indexWhere((t) => t.trackId == mediaItem.id);
    if (index >= 0) await removeQueueItemAt(index);
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    final wasCurrent = _queue.removeAt(index);
    if (wasCurrent) await _loadCurrent(autoplay: _player.playing);
  }

  /// Agrega un track a la cola (o justo después del actual).
  Future<void> enqueue(Track track, {bool next = false}) async {
    if (_queue.isEmpty) {
      await playQueue([track]);
      return;
    }
    _queue.addTrack(track, next: next);
  }

  /// Quita el track en [index] (usado por la QueueSheet).
  Future<void> removeAt(int index) => removeQueueItemAt(index);

  /// Drag & drop de la QueueSheet.
  void reorder(int oldIndex, int newIndex) => _queue.move(oldIndex, newIndex);

  /// Vacía la cola y detiene la reproducción.
  Future<void> clearQueue() async {
    await _player.stop();
    _queue.clear();
    _currentStream = null;
    _plannedTrackId = null;
    _streamController.add(null);
    mediaItem.add(null);
  }

  // -------------------------------------------------------------- Internos

  /// Carga y reproduce el track actual de la cola.
  Future<void> _loadCurrent(
      {bool autoplay = true, bool isRetry = false}) async {
    final track = _queue.current;
    if (track == null) {
      await _player.stop();
      return;
    }

    final generation = ++_loadingGeneration;
    // Se marca ANTES del primer await para que el listener de la cola
    // (que corre en un microtask) no dispare una segunda carga.
    _plannedTrackId = track.trackId;
    _setLoading(true);

    try {
      final info = await _resolveStream(track);
      if (generation != _loadingGeneration) return; // otra carga nos reemplazó

      _currentStream = info;
      _streamController.add(info);
      mediaItem.add(_mediaItemFor(track, info));

      final position = _player.position;
      await _player.setStream(
        info,
        initialPosition: isRetry ? position : Duration.zero,
      );
      if (autoplay) await _player.play();
      _broadcastState();
    } catch (error) {
      if (generation != _loadingGeneration) return;
      // Un reintento ante URL expirada o fallo transitorio.
      if (!isRetry) {
        try {
          _setLoading(false);
          return await _loadCurrent(autoplay: autoplay, isRetry: true);
        } catch (_) {
          // cae al manejo de error de abajo
        }
      }
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorCode: 1,
          errorMessage: error.toString(),
        ),
      );
      _errorController.add(error);
    } finally {
      if (generation == _loadingGeneration) _setLoading(false);
    }
  }

  void _onQueueChanged(QueueState state) {
    queue.add(state.tracks.map(_baseMediaItem).toList());

    final track = state.current;
    if (track == null) {
      _plannedTrackId = null;
      mediaItem.add(null);
      _broadcastState();
      return;
    }

    final loadedId = mediaItem.value?.id;
    final alreadyHandled =
        track.trackId == loadedId || track.trackId == _plannedTrackId;
    if (!alreadyHandled) {
      // La cola cambió de track activo por sí sola (auto-avance, reorder
      // sobre el actual, etc.).
      unawaited(_loadCurrent(autoplay: true));
    }
    _broadcastState();
  }

  void _handleCompletion() {
    final next = _queue.nextIndex();
    if (next == null) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
          playing: false,
        ),
      );
      return;
    }
    _queue.setCurrentIndex(next);
  }

  void _setLoading(bool value) {
    _loading = value;
    if (!_loadingController.isClosed) _loadingController.add(value);
    _broadcastState();
  }

  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.play,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessing(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _queue.currentIndex >= 0 ? _queue.currentIndex : null,
        repeatMode: _mapRepeat(_queue.repeat),
        shuffleMode: _queue.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  MediaItem _baseMediaItem(Track track) => _mediaItemFor(track, null);

  MediaItem _mediaItemFor(Track track, StreamInfo? info) {
    final artUrl = (info?.thumbnail != null && info!.thumbnail!.isNotEmpty)
        ? info.thumbnail!
        : track.thumbnailUrl;
    return MediaItem(
      id: track.trackId,
      title: track.displayTitle,
      artist: track.artist,
      album: track.album,
      duration: Duration(
        seconds: info?.durationSeconds ?? track.durationSeconds,
      ),
      artUri: artUrl.isEmpty ? null : Uri.tryParse(artUrl),
      extras: {
        'track': track.toJson(),
        if (info?.quality != null) 'quality': info!.quality,
        if (info?.codec != null) 'codec': info!.codec,
      },
    );
  }

  /// Reconstruye un [Track] desde el `extras` de un [MediaItem].
  Track? trackFromMediaItem(MediaItem item) {
    final raw = item.extras?['track'];
    if (raw is Map) return Track.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  static AudioProcessingState _mapProcessing(ProcessingState state) =>
      switch (state) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

  static AudioServiceRepeatMode _mapRepeat(LoopMode mode) => switch (mode) {
        LoopMode.off => AudioServiceRepeatMode.none,
        LoopMode.all => AudioServiceRepeatMode.all,
        LoopMode.one => AudioServiceRepeatMode.one,
      };

  @override
  Future<void> onTaskRemoved() async {
    await pause();
    await super.onTaskRemoved();
  }

  /// Libera recursos (llamado al cerrar la app).
  Future<void> dispose() async {
    await _queueSub?.cancel();
    await _playerSub?.cancel();
    await _streamController.close();
    await _loadingController.close();
    await _errorController.close();
    _queue.dispose();
    await _player.dispose();
  }
}
