import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/track.dart';
import 'player_provider.dart';
import 'queue_provider.dart';

/// Atajos de reproducción para las pantallas.
///
/// Mantiene las pantallas libres de detalles del handler de audio.
extension PlaybackActions on WidgetRef {
  /// Reproduce [track] dentro de [context] (o sola si no hay contexto).
  Future<void> playTrack(
    Track track, {
    List<Track>? context,
    int? index,
  }) {
    return read(playerProvider.notifier)
        .playTrack(track, context: context, startIndex: index);
  }

  /// Reproduce una lista completa, opcionalmente en orden aleatorio.
  Future<void> playAll(List<Track> tracks, {bool shuffled = false}) {
    return read(playerProvider.notifier)
        .playContext(tracks, shuffled: shuffled);
  }

  /// Agrega un track a la cola (o inmediatamente después del actual).
  Future<void> enqueueTrack(Track track, {bool next = false}) {
    return read(queueProvider.notifier).add(track, next: next);
  }

  /// Reproduce el track en la posición [index] de la cola.
  Future<void> jumpToQueueIndex(int index) {
    return read(queueProvider.notifier).jumpTo(index);
  }
}
