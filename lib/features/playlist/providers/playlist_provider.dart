import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/playlist.dart';
import '../../../core/models/track.dart';
import '../../../services/service_providers.dart';

/// Detalle de playlist editorial vía `GET /api/playlists/{uuid}`.
final playlistDetailProvider =
    FutureProvider.family<Playlist, String>((ref, playlistId) {
  return ref.watch(playlistServiceProvider).getPlaylist(playlistId);
});

/// Tracks de la playlist (contexto reproducible).
final playlistTracksProvider =
    Provider.family<List<Track>, String>((ref, playlistId) {
  return ref.watch(playlistDetailProvider(playlistId)).valueOrNull?.tracks ??
      const [];
});
