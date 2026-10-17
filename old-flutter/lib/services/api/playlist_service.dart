import '../../core/models/playlist.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/playlists/{playlistUuid}` (playlists editoriales del catálogo)
class PlaylistService {
  PlaylistService(this._client);

  final ApiClient _client;

  Future<Playlist> getPlaylist(String playlistId) async {
    final data = await _client.getJson(ApiEndpoints.playlist(playlistId));
    final map = Json.mapOf(data);
    final inner = map['playlist'];
    return Playlist.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }
}
