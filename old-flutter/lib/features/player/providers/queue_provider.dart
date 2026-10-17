import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/track.dart';
import '../../../services/service_providers.dart';
import '../audio/metmusic_audio_handler.dart';
import '../models/queue_state.dart';

/// Controlador de la cola de reproducción.
class QueueController extends StateNotifier<QueueState> {
  QueueController(this._ref) : super(QueueState.empty) {
    _handler = _ref.read(audioHandlerProvider);
    state = _handler.queueState;
    _sub = _handler.queueManager.stream.listen((queue) => state = queue);
  }

  final Ref _ref;
  late final MetMusicAudioHandler _handler;
  StreamSubscription<QueueState>? _sub;

  /// Agrega un track al final de la cola (o justo después del actual).
  Future<void> add(Track track, {bool next = false}) =>
      _handler.enqueue(track, next: next);

  /// Agrega una lista completa de tracks.
  Future<void> addAll(List<Track> tracks) async {
    for (final track in tracks) {
      await _handler.enqueue(track);
    }
  }

  /// Quita el track en [index].
  Future<void> removeAt(int index) => _handler.removeAt(index);

  /// Reordena la cola (drag & drop).
  void reorder(int oldIndex, int newIndex) =>
      _handler.reorder(oldIndex, newIndex);

  /// Salta al track en [index].
  Future<void> jumpTo(int index) => _handler.jumpTo(index);

  Future<void> clear() => _handler.clearQueue();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Estado de la cola actual.
final queueProvider = StateNotifierProvider<QueueController, QueueState>((ref) {
  return QueueController(ref);
});

/// Índice del track activo dentro de la cola.
final currentQueueIndexProvider = Provider<int>((ref) {
  return ref.watch(queueProvider.select((q) => q.currentIndex));
});
