import '../../core/models/track.dart';
import '../../core/models/track_details.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/tracks/{trackId}`
class TrackService {
  TrackService(this._client);

  final ApiClient _client;

  Future<Track> getTrack(String trackId) async {
    return Track.fromJson(await _unwrap(trackId));
  }

  /// El TrackSchema completo (ISRC, BPM, popularidad, copyright...) para el
  /// modal de metadatos.
  Future<TrackDetails> getTrackDetails(String trackId) async {
    return TrackDetails.fromJson(await _unwrap(trackId));
  }

  /// El backend puede envolver el track en {track: {...}}.
  Future<Map<String, dynamic>> _unwrap(String trackId) async {
    final data = await _client.getJson(ApiEndpoints.track(trackId));
    final map = Json.mapOf(data);
    final inner = map['track'];
    return inner is Map ? Map<String, dynamic>.from(inner) : map;
  }
}
