import '../../core/models/artist.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/artists/{artistId}`
class ArtistService {
  ArtistService(this._client);

  final ApiClient _client;

  Future<Artist> getArtist(String artistId) async {
    final data = await _client.getJson(ApiEndpoints.artist(artistId));
    final map = Json.mapOf(data);
    final inner = map['artist'];
    return Artist.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }
}
