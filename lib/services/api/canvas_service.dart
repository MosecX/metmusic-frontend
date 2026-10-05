import '../../core/models/canvas.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/canvas/{trackId}`
///
/// Un 404 se traduce en [CanvasMedia] `null` (no hay canvas disponible).
class CanvasService {
  CanvasService(this._client);

  final ApiClient _client;

  Future<CanvasMedia?> getCanvas(String trackId) async {
    try {
      final data = await _client.getJson(ApiEndpoints.canvas(trackId));
      final map = Json.mapOf(data);
      final inner = map['canvas'];
      final parsed = CanvasMedia.fromJson(
        inner is Map ? Map<String, dynamic>.from(inner) : map,
      );
      return parsed.url.isEmpty ? null : parsed;
    } on NotFoundApiException {
      return null;
    }
  }
}
