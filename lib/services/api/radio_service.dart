import '../../core/models/radio_mix.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/tracks/{trackId}/radio`
///
/// Contrato con el backend:
/// - **200** → estación + sus ~100 pistas de una (sin paginar; el primer
///   item es la semilla).
/// - **404** → la pista no tiene radio: resultado normal, no se reintenta
///   en bucle y el menú deja de ofrecerla.
/// - **401 / 400 / 429 / 5xx / red** → se propaga para que la UI muestre
///   `userMessage` (`ApiClient` ya reintenta una vez en 5xx).
///
/// El backend cachea la respuesta 15 min por pista: repetir dentro de esa
/// ventana es instantáneo. En frío tarda ~0.5–1 s.
class RadioService {
  RadioService(this._client);

  final ApiClient _client;

  /// Devuelve la estación de [trackId], o `null` si no existe (404) o si la
  /// respuesta venía vacía.
  Future<RadioStation?> getRadio(String trackId) async {
    try {
      final data = await _client.getJson(ApiEndpoints.radio(trackId));
      final station = RadioStation.fromJson(Json.mapOf(data));
      return station.items.isEmpty ? null : station;
    } on NotFoundApiException {
      return null;
    }
  }
}
