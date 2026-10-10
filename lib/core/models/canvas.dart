import '../utils/extensions.dart';

/// Resultado de `GET /api/canvas/{trackId}`.
///
/// Si el backend responde 404, no hay canvas y se muestra artwork estático.
class CanvasMedia {
  const CanvasMedia({
    required this.url,
    this.provider,
    this.kind = 'mp4',
    this.urlTall,
  });

  final String url;
  final String? provider;

  /// `hls` (playlist) o `mp4` (vídeo directo).
  final String kind;
  final String? urlTall;

  bool get isHls => kind.toLowerCase() == 'hls';
  bool get isMp4 => !isHls;

  /// URL efectiva a reproducir.
  ///
  /// Los canvases de Apple Music vienen en vertical: se usa `url_tall` cuando
  /// existe y se cae a la `url` normal si no. Spotify (y el resto) usan la
  /// `url` tal cual.
  String get displayUrl {
    final p = provider?.toLowerCase() ?? '';
    if (p.contains('apple') && urlTall != null && urlTall!.isNotEmpty) {
      return urlTall!;
    }
    return url;
  }

  factory CanvasMedia.fromJson(Map<String, dynamic> json) {
    return CanvasMedia(
      url: Json.strOr(json['url'], ''),
      provider: Json.str(json['provider']),
      kind: Json.strOr(json['kind'], 'mp4'),
      urlTall: Json.str(json['url_tall']),
    );
  }
}

/// Respuesta de un color dominante (no implementado por el backend aún).
class ArtworkColors {
  const ArtworkColors({required this.dominant, this.secondary});

  final int dominant;
  final int? secondary;

  factory ArtworkColors.fromJson(Map<String, dynamic> json) {
    return ArtworkColors(
      dominant: Json.intOr(json['dominant'], 0xFF0A0A0F),
      secondary: Json.asInt(json['secondary']),
    );
  }
}
