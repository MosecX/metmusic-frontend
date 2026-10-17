import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/artist.dart';
import '../../../core/models/track.dart';
import '../../../services/service_providers.dart';

/// Detalle de artista vía `GET /api/artists/{artistId}`.
final artistDetailProvider =
    FutureProvider.family<Artist, String>((ref, artistId) {
  return ref.watch(artistServiceProvider).getArtist(artistId);
});

/// Top tracks del artista (contexto reproducible).
final artistTopTracksProvider =
    Provider.family<List<Track>, String>((ref, artistId) {
  return ref.watch(artistDetailProvider(artistId)).valueOrNull?.topTracks ??
      const [];
});
