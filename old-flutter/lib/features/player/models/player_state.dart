import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/stream_info.dart';
import '../../../core/models/track.dart';
import 'queue_state.dart';

/// Estado completo del reproductor tal como lo consume la UI.
class MetPlayerState {
  const MetPlayerState({
    this.mediaItem,
    this.track,
    this.playing = false,
    this.processingState = ProcessingState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.stream,
    this.queue = QueueState.empty,
    this.loading = false,
    this.favorite = false,
    this.error,
  });

  final MediaItem? mediaItem;

  /// Track actual resuelto desde la cola.
  final Track? track;
  final bool playing;
  final ProcessingState processingState;
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final StreamInfo? stream;
  final QueueState queue;
  final bool loading;
  final bool favorite;
  final Object? error;

  static const MetPlayerState idle = MetPlayerState();

  bool get hasTrack => track != null || mediaItem != null;

  bool get isPlaying => playing && !isBuffering;

  bool get isBuffering =>
      processingState == ProcessingState.loading ||
      processingState == ProcessingState.buffering;

  bool get isCompleted => processingState == ProcessingState.completed;

  /// Duración efectiva (la del MediaItem sirve como fallback de metadatos).
  Duration get effectiveDuration {
    if (duration > Duration.zero) return duration;
    final meta = mediaItem?.duration;
    if (meta != null && meta > Duration.zero) return meta;
    return track?.duration ?? Duration.zero;
  }

  double get progress {
    final total = effectiveDuration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  String get title => track?.displayTitle ?? mediaItem?.title ?? '';

  String get artist => track?.artist ?? mediaItem?.artist ?? '';

  String get album => track?.album ?? mediaItem?.album ?? '';

  String get artworkUrl => stream?.thumbnail ?? track?.thumbnailUrl ?? '';

  MetPlayerState copyWith({
    MediaItem? mediaItem,
    Track? track,
    bool? playing,
    ProcessingState? processingState,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    StreamInfo? stream,
    QueueState? queue,
    bool? loading,
    bool? favorite,
    Object? error,
    bool clearError = false,
  }) {
    return MetPlayerState(
      mediaItem: mediaItem ?? this.mediaItem,
      track: track ?? this.track,
      playing: playing ?? this.playing,
      processingState: processingState ?? this.processingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      stream: stream ?? this.stream,
      queue: queue ?? this.queue,
      loading: loading ?? this.loading,
      favorite: favorite ?? this.favorite,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
