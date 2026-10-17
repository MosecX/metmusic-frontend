import '../../core/models/lyrics.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/extensions.dart';

/// `GET /api/lyrics/{trackId}`
///
/// Contrato con el backend:
/// - **404** → las tres fuentes no tienen letras del tema: es un resultado
///   normal, se devuelve `null` (la UI cae a la fuente local) y **no** se
///   reintenta en bucle.
/// - **401** → token mal/ausente: no se reintenta.
/// - **429** → un reintento con backoff; si vuelve a fallar, `null` (local).
/// - **5xx** → `ApiClient` ya reintenta una vez; si persiste, `null` (local).
class LyricsService {
  LyricsService(this._client);

  final ApiClient _client;

  Future<Lyrics?> getLyrics(String trackId) async {
    try {
      return await _fetch(trackId);
    } on NotFoundApiException {
      return null;
    } on UnauthorizedApiException {
      return null;
    } on ServerApiException catch (error) {
      if (error.statusCode != 429) return null;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      try {
        return await _fetch(trackId);
      } on ApiException {
        return null;
      }
    } on ApiException {
      return null;
    }
  }

  Future<Lyrics?> _fetch(String trackId) async {
    final data = await _client.getJson(ApiEndpoints.lyrics(trackId));
    final map = Json.mapOf(data);
    final inner = map['lyrics'];
    final lyrics = Lyrics.fromJson(
      inner is Map ? Map<String, dynamic>.from(inner) : map,
    );
    return lyrics.hasLyrics ? lyrics : null;
  }
}
