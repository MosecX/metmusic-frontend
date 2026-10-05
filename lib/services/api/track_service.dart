import '../../core/models/track.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/tracks/{trackId}`
class TrackService {
  TrackService(this._client);

  final ApiClient _client;

  Future<Track> getTrack(String trackId) async {
    final data = await _client.getJson(ApiEndpoints.track(trackId));
    final map = Json.mapOf(data);
    // El backend puede envolver el track en {track: {...}}.
    final inner = map['track'];
    return Track.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }
}
