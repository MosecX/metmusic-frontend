import 'package:just_audio/just_audio.dart';

import '../../../core/models/track.dart';

/// Fotografía inmutable de la cola de reproducción.
class QueueState {
  const QueueState({
    this.tracks = const [],
    this.currentIndex = -1,
    this.shuffle = false,
    this.repeat = LoopMode.off,
  });

  final List<Track> tracks;
  final int currentIndex;
  final bool shuffle;
  final LoopMode repeat;

  static const QueueState empty = QueueState();

  Track? get current => (currentIndex >= 0 && currentIndex < tracks.length)
      ? tracks[currentIndex]
      : null;

  bool get isEmpty => tracks.isEmpty;

  bool get hasNext => currentIndex < tracks.length - 1;
  bool get hasPrevious => currentIndex > 0;

  bool get repeatAll => repeat == LoopMode.all;
  bool get repeatOne => repeat == LoopMode.one;

  QueueState copyWith({
    List<Track>? tracks,
    int? currentIndex,
    bool? shuffle,
    LoopMode? repeat,
  }) {
    return QueueState(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffle: shuffle ?? this.shuffle,
      repeat: repeat ?? this.repeat,
    );
  }
}
