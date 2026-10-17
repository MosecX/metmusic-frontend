import '../../core/models/album.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/albums/{albumId}`
class AlbumService {
  AlbumService(this._client);

  final ApiClient _client;

  Future<Album> getAlbum(String albumId) async {
    final data = await _client.getJson(ApiEndpoints.album(albumId));
    final map = Json.mapOf(data);
    final inner = map['album'];
    return Album.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }
}
