import '../utils/extensions.dart';
import '../utils/image_utils.dart';
import 'thumbnail.dart';

/// Una canción tal como la devuelve el backend.
class Track {
  const Track({
    required this.trackId,
    required this.title,
    this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.durationSeconds = 0,
    this.isrc,
    this.thumbnails = const [],
    this.quality,
    this.explicit = false,
    this.version,
  });

  final String trackId;
  final String title;
  final String? artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final int durationSeconds;
  final String? isrc;
  final List<Thumbnail> thumbnails;
  final String? quality;
  final bool explicit;
  final String? version;

  Duration get duration => Duration(seconds: durationSeconds);

  /// Título con el sufijo de versión cuando existe (ej. "Song (Remix)").
  String get displayTitle =>
      (version != null && version!.trim().isNotEmpty)
          ? '$title (${version!.trim()})'
          : title;

  String get thumbnailUrl => ImageUtils.cardThumbnail(thumbnails);
  String get listThumbnailUrl => ImageUtils.listThumbnail(thumbnails);

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      trackId: Json.strOr(json['track_id'] ?? json['id'], ''),
      title: Json.strOr(json['title'], 'Desconocido'),
      artist: Json.str(json['artist'] ?? json['artist_name']),
      artistId: Json.str(json['artist_id']),
      album: Json.str(json['album'] ?? json['album_title']),
      albumId: Json.str(json['album_id']),
      durationSeconds: Json.intOr(json['duration_seconds'] ?? json['duration'], 0),
      isrc: Json.str(json['isrc']),
      thumbnails: Thumbnail.listFrom(json['thumbnails'] ?? json['images']),
      quality: Json.str(json['quality']),
      explicit: Json.boolOr(json['explicit'], false),
      version: Json.str(json['version']),
    );
  }

  Map<String, dynamic> toJson() => {
        'track_id': trackId,
        'title': title,
        if (artist != null) 'artist': artist,
        if (artistId != null) 'artist_id': artistId,
        if (album != null) 'album': album,
        if (albumId != null) 'album_id': albumId,
        'duration_seconds': durationSeconds,
        if (isrc != null) 'isrc': isrc,
        'thumbnails': thumbnails.map((t) => t.toJson()).toList(),
        if (quality != null) 'quality': quality,
        'explicit': explicit,
        if (version != null) 'version': version,
      };

  Track copyWith({
    String? trackId,
    String? title,
    String? artist,
    String? artistId,
    String? album,
    String? albumId,
    int? durationSeconds,
    String? isrc,
    List<Thumbnail>? thumbnails,
    String? quality,
    bool? explicit,
    String? version,
  }) {
    return Track(
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isrc: isrc ?? this.isrc,
      thumbnails: thumbnails ?? this.thumbnails,
      quality: quality ?? this.quality,
      explicit: explicit ?? this.explicit,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Track && other.trackId == trackId;

  @override
  int get hashCode => trackId.hashCode;
}
