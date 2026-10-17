import '../utils/extensions.dart';

/// Resultado de `GET /api/stream/{trackId}`.
///
/// El backend ya resolvió el proveedor (Qobuz/Tidal); la app solo reproduce.
class StreamInfo {
  const StreamInfo({
    required this.url,
    required this.trackId,
    this.provider,
    this.quality,
    this.codec,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.expiresIn,
    this.title,
    this.artist,
    this.album,
    this.thumbnail,
    this.durationSeconds,
    this.isrc,
    this.manifestType = 'direct',
    this.isPreview = false,
    this.fetchedAt,
  });

  final String url;
  final String trackId;
  final String? provider;
  final String? quality;
  final String? codec;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? expiresIn;
  final String? title;
  final String? artist;
  final String? album;
  final String? thumbnail;
  final int? durationSeconds;
  final String? isrc;

  /// `direct` (progresivo) o `dash` (manifiesto DASH).
  final String manifestType;
  final bool isPreview;

  /// Momento en que se obtuvo la URL (para detectar expiración).
  final DateTime? fetchedAt;

  bool get isDash => manifestType.toLowerCase() == 'dash';
  bool get isDirect => !isDash;

  /// True si la URL ya expiró o está por expirar (margen de 30 s).
  bool get isExpired {
    if (expiresIn == null || fetchedAt == null) return false;
    final expiry = fetchedAt!.add(Duration(seconds: expiresIn!));
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 30)));
  }

  /// Etiqueta legible de calidad, ej. `FLAC 24/96` o `AAC 320 kbps`.
  String get qualityLabel {
    final parts = <String>[];
    final codecLabel = (codec ?? '').toUpperCase();
    if (codecLabel.isNotEmpty) parts.add(codecLabel);
    if (bitDepth != null && sampleRate != null) {
      parts.add('$bitDepth/${(sampleRate! / 1000).round()}');
    } else if (bitrate != null) {
      parts.add('${(bitrate! / 1000).round()} kbps');
    }
    if (parts.isEmpty && quality != null) return quality!;
    return parts.isEmpty ? 'Auto' : parts.join(' ');
  }

  factory StreamInfo.fromJson(Map<String, dynamic> json) {
    return StreamInfo(
      url: Json.strOr(json['url'], ''),
      trackId: Json.strOr(json['track_id'], ''),
      provider: Json.str(json['provider']),
      quality: Json.str(json['quality']),
      codec: Json.str(json['codec']),
      bitrate: Json.asInt(json['bitrate']),
      sampleRate: Json.asInt(json['sample_rate']),
      bitDepth: Json.asInt(json['bit_depth']),
      expiresIn: Json.asInt(json['expires_in']),
      title: Json.str(json['title']),
      artist: Json.str(json['artist']),
      album: Json.str(json['album']),
      thumbnail: Json.str(json['thumbnail']),
      durationSeconds: Json.asInt(json['duration_seconds']),
      isrc: Json.str(json['isrc']),
      manifestType: Json.strOr(json['manifest_type'], 'direct'),
      isPreview: Json.boolOr(json['is_preview'], false),
      fetchedAt: DateTime.now(),
    );
  }
}
