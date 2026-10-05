import '../../core/models/lyrics.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/lyrics/{trackId}`
class LyricsService {
  LyricsService(this._client);

  final ApiClient _client;

  Future<Lyrics> getLyrics(String trackId) async {
    final data = await _client.getJson(ApiEndpoints.lyrics(trackId));
    final map = Json.mapOf(data);
    final inner = map['lyrics'];
    return Lyrics.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
  }
}
