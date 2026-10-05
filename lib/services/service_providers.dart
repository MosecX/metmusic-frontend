import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../features/player/audio/metmusic_audio_handler.dart';
import 'api/album_service.dart';
import 'api/artist_service.dart';
import 'api/canvas_service.dart';
import 'api/explore_service.dart';
import 'api/health_service.dart';
import 'api/lyrics_service.dart';
import 'api/playlist_service.dart';
import 'api/search_service.dart';
import 'api/stream_service.dart';
import 'api/track_service.dart';
import 'api/user_service.dart';
import 'local/favorites_service.dart';
import 'local/history_service.dart';
import 'local/settings_storage.dart';

// ---------------------------------------------------------------------------
// Almacenamiento local — se sobrescribe en main() con instancias ya abiertas.
// ---------------------------------------------------------------------------

final settingsStorageProvider = Provider<SettingsStorage>(
  (ref) => throw UnimplementedError('settingsStorageProvider debe sobrescribirse'),
);

final historyServiceProvider = Provider<HistoryService>(
  (ref) => throw UnimplementedError('historyServiceProvider debe sobrescribirse'),
);

final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => throw UnimplementedError('favoritesServiceProvider debe sobrescribirse'),
);

// ---------------------------------------------------------------------------
// Audio handler — se sobrescribe en main() tras AudioService.init().
// ---------------------------------------------------------------------------

final audioHandlerProvider = Provider<MetMusicAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider debe sobrescribirse'),
);

// ---------------------------------------------------------------------------
// Red
// ---------------------------------------------------------------------------

/// URL base activa (editable en Settings).
final baseUrlHolderProvider = Provider<BaseUrlHolder>(
  (ref) => BaseUrlHolder(ref.read(settingsStorageProvider).baseUrl),
);

/// Token Bearer activo (editable en Settings).
final apiTokenHolderProvider = Provider<ApiTokenHolder>(
  (ref) => ApiTokenHolder(ref.read(settingsStorageProvider).apiToken),
);

/// Cliente Dio compartido por todos los services.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: ref.watch(baseUrlHolderProvider),
    token: ref.watch(apiTokenHolderProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

// ---------------------------------------------------------------------------
// Services HTTP
// ---------------------------------------------------------------------------

final healthServiceProvider = Provider<HealthService>(
  (ref) => HealthService(ref.watch(apiClientProvider)),
);

final searchServiceProvider = Provider<SearchService>(
  (ref) => SearchService(ref.watch(apiClientProvider)),
);

final trackServiceProvider = Provider<TrackService>(
  (ref) => TrackService(ref.watch(apiClientProvider)),
);

final albumServiceProvider = Provider<AlbumService>(
  (ref) => AlbumService(ref.watch(apiClientProvider)),
);

final artistServiceProvider = Provider<ArtistService>(
  (ref) => ArtistService(ref.watch(apiClientProvider)),
);

final playlistServiceProvider = Provider<PlaylistService>(
  (ref) => PlaylistService(ref.watch(apiClientProvider)),
);

final streamServiceProvider = Provider<StreamService>(
  (ref) => StreamService(ref.watch(apiClientProvider)),
);

final exploreServiceProvider = Provider<ExploreService>(
  (ref) => ExploreService(ref.watch(apiClientProvider)),
);

final userServiceProvider = Provider<UserService>(
  (ref) => UserService(ref.watch(apiClientProvider)),
);

final lyricsServiceProvider = Provider<LyricsService>(
  (ref) => LyricsService(ref.watch(apiClientProvider)),
);

final canvasServiceProvider = Provider<CanvasService>(
  (ref) => CanvasService(ref.watch(apiClientProvider)),
);

/// Indica si el backend está alcanzable (para degradar a datos locales).
final connectivityProvider = FutureProvider<bool>((ref) async {
  final client = ref.watch(apiClientProvider);
  return client.ping();
});
