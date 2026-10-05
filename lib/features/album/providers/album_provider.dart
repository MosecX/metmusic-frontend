import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/album.dart';
import '../../../core/models/track.dart';
import '../../../services/service_providers.dart';

/// Detalle de álbum vía `GET /api/albums/{albumId}`.
final albumDetailProvider = FutureProvider.family<Album, String>((ref, albumId) {
  return ref.watch(albumServiceProvider).getAlbum(albumId);
});

/// Tracks del álbum ya normalizados (con contexto para reproducir).
final albumTracksProvider = Provider.family<List<Track>, String>((ref, albumId) {
  return ref.watch(albumDetailProvider(albumId)).valueOrNull?.tracks ?? const [];
});
