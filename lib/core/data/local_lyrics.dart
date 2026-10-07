import '../models/lyrics.dart';

/// Fuente local de letras embebidas en la app.
///
/// Contrato con el backend: ante un **404** de `GET /api/lyrics/{trackId}`
/// (las tres fuentes consultadas no tienen letras —o el tema es
/// instrumental—) el frontend usa esta fuente local y no vuelve a
/// consultar en bucle. Idem cuando la petición falla tras agotar los
/// reintentos (401/429/5xx): se degrada a local.
///
/// Para sumar letras: agregar `'trackId': 'texto plano'` en [_byTrackId]
/// (o migrar el mapa a un JSON en `assets/` cuando crezca).
class LocalLyrics {
  LocalLyrics._();

  /// Letras embebidas por trackId (texto plano, con `\n` entre líneas).
  static const Map<String, String> _byTrackId = <String, String>{
    // '1550546': 'One more time\nWe\'re gonna celebrate...',
  };

  /// Letras locales del track, o `null` si no están embebidas.
  static Lyrics? forTrack(String trackId) {
    final text = _byTrackId[trackId];
    if (text == null || text.trim().isEmpty) return null;
    return Lyrics(lyrics: text, trackId: trackId);
  }
}
