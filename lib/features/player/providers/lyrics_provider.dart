import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/lyrics.dart';
import '../../../services/service_providers.dart';

/// Letras de un track (`GET /api/lyrics/{trackId}`).
///
/// Se deja listo para cuando se agregue la vista de letras sincronizadas:
/// el backend ya devuelve `synced_lines` con `time_ms`.
final lyricsProvider =
    FutureProvider.family<Lyrics?, String>((ref, trackId) async {
  if (trackId.isEmpty) return null;
  return ref.watch(lyricsServiceProvider).getLyrics(trackId);
});
