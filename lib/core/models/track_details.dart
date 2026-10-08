import '../utils/extensions.dart';

/// Metadatos completos de una pista (`GET /api/tracks/{trackId}`).
///
/// A diferencia del modelo `Track` (que sólo trae lo que muestran las
/// listas), éste parsea el TrackSchema entero: ISRC, BPM, popularidad,
/// copyright y si está lista para stream.
class TrackDetails {
  const TrackDetails({
    required this.trackId,
    required this.title,
    required this.durationSeconds,
    this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.isrc,
    this.quality,
    this.version,
    this.copyright,
    this.popularity,
    this.bpm,
    this.peak,
    this.explicit = false,
    this.streamReady = false,
  });

  final String trackId;
  final String title;
  final String? artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final int durationSeconds;
  final String? isrc;
  final String? quality;
  final String? version;
  final String? copyright;
  final double? popularity;
  final double? bpm;
  final double? peak;
  final bool explicit;
  final bool streamReady;

  Duration get duration => Duration(seconds: durationSeconds);

  factory TrackDetails.fromJson(Map<String, dynamic> json) {
    return TrackDetails(
      trackId: Json.strOr(json['track_id'] ?? json['id'], ''),
      title: Json.strOr(json['title'], 'Desconocido'),
      artist: Json.str(json['artist'] ?? json['artist_name']),
      artistId: Json.str(json['artist_id']),
      album: Json.str(json['album'] ?? json['album_title']),
      albumId: Json.str(json['album_id']),
      durationSeconds:
          Json.intOr(json['duration_seconds'] ?? json['duration'], 0),
      isrc: Json.str(json['isrc']),
      quality: Json.str(json['quality']),
      version: Json.str(json['version']),
      copyright: Json.str(json['copyright']),
      popularity: _num(json['popularity']),
      bpm: _num(json['bpm']),
      peak: _num(json['peak']),
      explicit: Json.boolOr(json['explicit'], false),
      streamReady: Json.boolOr(json['stream_ready'], false),
    );
  }
}

/// Entero o decimal tolerante (`bpm` puede venir como string).
double? _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
