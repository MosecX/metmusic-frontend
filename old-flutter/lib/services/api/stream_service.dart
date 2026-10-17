import '../../core/constants/api_constants.dart';
import '../../core/models/stream_info.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/stream/{trackId}` — el endpoint central de reproducción.
///
/// Nunca se reintenta desde el interceptor: cada llamada resuelve una URL
/// nueva (Qobuz o Tidal) y las URLs son de un solo uso.
class StreamService {
  StreamService(this._client);

  final ApiClient _client;

  Future<StreamInfo> getStream(
    String trackId, {
    AudioQualityPreference? quality,
  }) async {
    final data = await _client.getJson(
      ApiEndpoints.stream(trackId),
      query: quality == null ? null : {'quality': quality.value},
    );
    final info = StreamInfo.fromJson(Json.mapOf(data));
    if (info.url.isEmpty) {
      throw const ParseApiException(
          'El backend no devolvió una URL reproducible');
    }
    return info;
  }
}
