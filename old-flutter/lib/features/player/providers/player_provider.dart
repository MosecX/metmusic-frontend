import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/history_entry.dart';
import '../../../core/models/track.dart';
import '../../../services/api/user_service.dart';
import '../../../services/local/favorites_service.dart';
import '../../../services/local/history_service.dart';
import '../../../services/service_providers.dart';
import '../../library/providers/library_provider.dart';
import '../audio/metmusic_audio_handler.dart';
import '../models/player_state.dart';

/// Controlador del reproductor: ensambla el estado del [MetMusicAudioHandler]
/// y expone las acciones que consume la UI.
class PlayerController extends StateNotifier<MetPlayerState> {
  PlayerController(this._ref) : super(MetPlayerState.idle) {
    _handler = _ref.read(audioHandlerProvider);
    _favorites = _ref.read(favoritesServiceProvider);
    _history = _ref.read(historyServiceProvider);
    _user = _ref.read(userServiceProvider);
    _bind();
  }

  final Ref _ref;
  late final MetMusicAudioHandler _handler;
  late final FavoritesService _favorites;
  late final HistoryService _history;
  late final UserService _user;

  final List<StreamSubscription<dynamic>> _subs = [];

  String? _lastTrackId;
  Duration _lastPosition = Duration.zero;
  Duration _lastDuration = Duration.zero;

  MetMusicAudioHandler get handler => _handler;

  /// Errores de reproducción (la shell los muestra como SnackBar).
  Stream<Object> get errors => _handler.errorStream;

  void _bind() {
    _subs.add(_handler.playerService.playerStateStream.listen((ps) {
      state = state.copyWith(
        playing: ps.playing,
        processingState: ps.processingState,
      );
    }));

    _subs.add(_handler.positionStream.listen((position) {
      _lastPosition = position;
      state = state.copyWith(position: position);
    }));

    _subs.add(_handler.durationStream.listen((duration) {
      if (duration != null) {
        _lastDuration = duration;
        state = state.copyWith(duration: duration);
      }
    }));

    _subs.add(_handler.mediaItem.listen(_onMediaItemChanged));

    _subs.add(_handler.streamInfoStream.listen((info) {
      state = state.copyWith(stream: info);
    }));

    _subs.add(_handler.loadingStream.listen((loading) {
      state = state.copyWith(loading: loading);
    }));

    _subs.add(_handler.errorStream.listen((error) {
      state = state.copyWith(error: error);
    }));

    _subs.add(_handler.queueManager.stream.listen((queue) {
      state = state.copyWith(
        queue: queue,
        track: queue.current ?? state.track,
      );
    }));
  }

  void _onMediaItemChanged(MediaItem? item) {
    final previousId = _lastTrackId;

    if (item == null) {
      _lastTrackId = null;
      state = state.copyWith(mediaItem: null, track: null, favorite: false);
      return;
    }

    // Reporta el track anterior al historial (si sonó lo suficiente).
    if (previousId != null && previousId != item.id) {
      _reportHistory(previousId);
    }

    final track = _handler.trackFromMediaItem(item);
    _lastTrackId = item.id;
    _lastPosition = Duration.zero;

    state = state.copyWith(
      mediaItem: item,
      track: track,
      favorite: _favorites.isFavorite(item.id),
      clearError: true,
    );
  }

  /// Persiste la reproducción en local (Hive) y en el backend.
  void _reportHistory(String trackId) {
    final playedMs = _lastPosition.inMilliseconds;
    if (playedMs < 3000) return;

    final durationMs = _lastDuration.inMilliseconds;
    final completed = durationMs > 0 && playedMs >= durationMs - 2000;
    Track? track;
    for (final candidate in _handler.queueManager.tracks) {
      if (candidate.trackId == trackId) {
        track = candidate;
        break;
      }
    }

    // Local primero: la Library funciona sin red.
    unawaited(
      _history.add(
        HistoryEntry(
          trackId: trackId,
          playedAt: DateTime.now(),
          playedMs: playedMs,
          completed: completed,
          track: track,
        ),
      ),
    );

    // Sincronización con el backend (silenciosa si falla).
    unawaited(
      _user
          .addHistory(
            trackId: trackId,
            playedMs: playedMs,
            completed: completed,
          )
          .catchError((_) {}),
    );
  }

  // ---------------------------------------------------------------- Acciones

  /// Reproduce un track suelto o dentro de un contexto (álbum, playlist...).
  Future<void> playTrack(
    Track track, {
    List<Track>? context,
    int? startIndex,
  }) async {
    if (context != null && context.isNotEmpty) {
      final index =
          startIndex ?? context.indexWhere((t) => t.trackId == track.trackId);
      await _handler.playQueue(
        context,
        startIndex: index < 0 ? 0 : index,
      );
    } else {
      await _handler.playSingle(track);
    }
  }

  /// Reproduce una lista completa desde [startIndex].
  Future<void> playContext(
    List<Track> tracks, {
    int startIndex = 0,
    bool shuffled = false,
  }) async {
    if (tracks.isEmpty) return;
    if (shuffled) {
      await _handler.setShuffleMode(AudioServiceShuffleMode.all);
    }
    await _handler.playQueue(tracks, startIndex: startIndex);
  }

  /// Reproduce el track en la posición [index] de la cola actual.
  Future<void> jumpTo(int index) => _handler.jumpTo(index);

  Future<void> togglePlayPause() async {
    if (state.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> next() => _handler.skipToNext();

  Future<void> previous() => _handler.skipToPrevious();

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> seekToFraction(double fraction) {
    final total = state.effectiveDuration;
    if (total <= Duration.zero) return Future.value();
    final target = Duration(
      milliseconds: (total.inMilliseconds * fraction.clamp(0.0, 1.0)).round(),
    );
    return _handler.seek(target);
  }

  Future<void> seekForward([Duration step = const Duration(seconds: 15)]) =>
      _handler.seek(state.position + step);

  Future<void> seekBackward([Duration step = const Duration(seconds: 15)]) {
    final target = state.position - step;
    return _handler.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> toggleShuffle() => _handler.toggleShuffle();

  Future<void> cycleRepeat() => _handler.cycleRepeat();

  Future<void> setVolume(double value) =>
      _handler.playerService.setVolume(value);

  /// Alterna favorito.
  ///
  /// La lógica de persistencia local + sincronización vive en
  /// [FavoritesController] (fuente de verdad única).
  Future<bool> toggleFavorite() async {
    final track = state.track;
    if (track == null) return false;
    final nowFavorite =
        await _ref.read(favoritesListProvider.notifier).toggle(track);
    state = state.copyWith(favorite: nowFavorite);
    return nowFavorite;
  }

  Future<void> addToQueue(Track track, {bool next = false}) =>
      _handler.enqueue(track, next: next);

  Future<void> removeFromQueue(int index) => _handler.removeAt(index);

  void reorderQueue(int oldIndex, int newIndex) =>
      _handler.reorder(oldIndex, newIndex);

  Future<void> clearQueue() => _handler.clearQueue();

  Future<void> stop() => _handler.stop();

  /// Limpia el error mostrado en la UI.
  void dismissError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}

/// Estado del reproductor.
final playerProvider =
    StateNotifierProvider<PlayerController, MetPlayerState>((ref) {
  return PlayerController(ref);
});

/// Track actualmente reproduciéndose (null si no hay nada).
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(playerProvider.select((s) => s.track));
});

/// True cuando hay un track activo (para mostrar el MiniPlayer).
final hasActiveTrackProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider.select((s) => s.hasTrack));
});

/// Ratio de progreso 0..1 del track actual.
final playerProgressProvider = Provider<double>((ref) {
  return ref.watch(playerProvider.select((s) => s.progress));
});

/// True si el track actual está marcado como favorito.
final currentTrackIsFavoriteProvider = Provider<bool>((ref) {
  final trackId = ref.watch(playerProvider.select((s) => s.track?.trackId));
  if (trackId == null) return false;
  return ref.watch(isFavoriteProvider(trackId));
});
