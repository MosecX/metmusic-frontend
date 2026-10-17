import '../../core/constants/app_constants.dart';
import '../../core/models/history_entry.dart';
import '../../core/models/track.dart';
import '../../core/models/user_playlist.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// Endpoints de usuario: playlists propias, historial y favoritos.
class UserService {
  UserService(this._client);

  final ApiClient _client;

  // ---------------------------------------------------------------- Playlists

  /// `POST /api/user/playlists`
  Future<UserPlaylist> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    final data = await _client.postJson(
      ApiEndpoints.userPlaylists,
      body: {
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
      },
    );
    return UserPlaylist.fromJson(Json.mapOf(data));
  }

  /// `GET /api/user/playlists`
  Future<List<UserPlaylist>> getPlaylists() async {
    final data = await _client.getJson(ApiEndpoints.userPlaylists);
    if (data is List) return UserPlaylist.listFrom(data);
    final map = Json.mapOf(data);
    for (final key in ['playlists', 'items', 'results', 'data']) {
      final value = map[key];
      if (value is List) return UserPlaylist.listFrom(value);
    }
    return const [];
  }

  /// `GET /api/user/playlists/{id}`
  Future<UserPlaylist> getPlaylist(String id) async {
    final data = await _client.getJson(ApiEndpoints.userPlaylist(id));
    final map = Json.mapOf(data);
    final inner = map['playlist'];
    return UserPlaylist.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }

  /// `PUT /api/user/playlists/{id}`
  Future<UserPlaylist> updatePlaylist(
    String id, {
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    final data = await _client.putJson(
      ApiEndpoints.userPlaylist(id),
      body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
      },
    );
    final map = Json.mapOf(data);
    if (map.isEmpty) {
      return UserPlaylist(id: id, name: name ?? '', description: description);
    }
    final inner = map['playlist'];
    return UserPlaylist.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }

  /// `DELETE /api/user/playlists/{id}`
  Future<void> deletePlaylist(String id) async {
    await _client.deleteJson(ApiEndpoints.userPlaylist(id));
  }

  /// `POST /api/user/playlists/{id}/tracks` con `["trackId", ...]`
  Future<void> addTracks(String id, List<String> trackIds) async {
    if (trackIds.isEmpty) return;
    await _client.postJson(ApiEndpoints.userPlaylistTracks(id), body: trackIds);
  }

  /// `DELETE /api/user/playlists/{id}/tracks/{trackId}`
  Future<void> removeTrack(String id, String trackId) async {
    await _client.deleteJson(ApiEndpoints.userPlaylistTrack(id, trackId));
  }

  /// `PUT /api/user/playlists/{id}/reorder` con el orden completo de ids.
  Future<void> reorder(String id, List<String> orderedTrackIds) async {
    await _client.putJson(
      ApiEndpoints.userPlaylistReorder(id),
      body: orderedTrackIds,
    );
  }

  // ----------------------------------------------------------------- History

  /// `POST /api/user/history`
  Future<void> addHistory({
    required String trackId,
    int playedMs = 0,
    bool completed = false,
  }) async {
    await _client.postJson(
      ApiEndpoints.userHistory,
      body: {
        'track_id': trackId,
        'played_ms': playedMs,
        'completed': completed,
      },
    );
  }

  /// `GET /api/user/history?limit=&offset=`
  Future<List<HistoryEntry>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _client.getJson(
      ApiEndpoints.userHistory,
      query: {'limit': limit, 'offset': offset},
    );
    if (data is List) return HistoryEntry.listFrom(data);
    final map = Json.mapOf(data);
    for (final key in ['history', 'items', 'results', 'data']) {
      final value = map[key];
      if (value is List) return HistoryEntry.listFrom(value);
    }
    return const [];
  }

  /// `DELETE /api/user/history`
  Future<void> clearHistory() async {
    await _client.deleteJson(ApiEndpoints.userHistory);
  }

  // --------------------------------------------------------------- Favorites

  /// `POST /api/user/favorites/{trackId}`
  Future<void> addFavorite(String trackId) async {
    await _client.postJson(ApiEndpoints.userFavorite(trackId));
  }

  /// `DELETE /api/user/favorites/{trackId}`
  Future<void> removeFavorite(String trackId) async {
    await _client.deleteJson(ApiEndpoints.userFavorite(trackId));
  }

  /// `GET /api/user/favorites?limit=&offset=`
  Future<List<Track>> getFavorites({
    int limit = AppConstants.favoritesPageSize,
    int offset = 0,
  }) async {
    final data = await _client.getJson(
      ApiEndpoints.userFavorites,
      query: {'limit': limit, 'offset': offset},
    );
    if (data is List) return Json.maps(data).map(Track.fromJson).toList();
    final map = Json.mapOf(data);
    for (final key in ['favorites', 'tracks', 'items', 'results', 'data']) {
      final value = map[key];
      if (value is List) {
        return Json.maps(value).map(Track.fromJson).toList(growable: false);
      }
    }
    return const [];
  }

  /// `GET /api/user/favorites/check?ids=1,2,3` → set de ids favoritos.
  Future<Set<String>> checkFavorites(List<String> trackIds) async {
    if (trackIds.isEmpty) return <String>{};
    final data = await _client.getJson(
      ApiEndpoints.userFavoritesCheck,
      query: {'ids': trackIds.join(',')},
    );
    if (data is List) return Json.strings(data).toSet();
    final map = Json.mapOf(data);
    final value = map['favorites'] ?? map['ids'] ?? map['track_ids'];
    if (value is List) return Json.strings(value).toSet();
    if (map.values.every((v) => v is bool)) {
      return map.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toSet();
    }
    return <String>{};
  }
}
