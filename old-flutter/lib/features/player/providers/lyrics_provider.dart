import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_lyrics.dart';
import '../../../core/models/lyrics.dart';
import '../../../services/service_providers.dart';

/// Letras de un track (`GET /api/lyrics/{trackId}`).
///
/// El servicio ya cumple el contrato de errores (404/401/429/5xx → `null`,
/// sin reintentos en bucle); acá se aplica la última pieza: si no vinieron
/// letras del backend se degrada a la fuente local embebida en el bundle.
/// `null` final = no hay letras para mostrar.
final lyricsProvider =
    FutureProvider.family<Lyrics?, String>((ref, trackId) async {
  if (trackId.isEmpty) return null;
  final remote = await ref.watch(lyricsServiceProvider).getLyrics(trackId);
  return remote ?? LocalLyrics.forTrack(trackId);
});
