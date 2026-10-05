import '../utils/extensions.dart';
import '../utils/image_utils.dart';
import 'thumbnail.dart';
import 'track.dart';

/// Álbum. El mismo modelo sirve para resúmenes (búsqueda) y detalle.
class Album {
  const Album({
    required this.albumId,
    required this.title,
    this.artist,
    this.artistId,
    this.releaseDate,
    this.numberOfTracks,
    this.durationSeconds,
    this.thumbnails = const [],
    this.tracks = const [],
    this.copyright,
    this.upc,
  });

  final String albumId;
  final String title;
  final String? artist;
  final String? artistId;
  final String? releaseDate;
  final int? numberOfTracks;
  final int? durationSeconds;
  final List<Thumbnail> thumbnails;
  final List<Track> tracks;
  final String? copyright;
  final String? upc;

  String get year =>
      (releaseDate != null && releaseDate!.length >= 4) ? releaseDate!.substring(0, 4) : '';

  String get thumbnailUrl => ImageUtils.cardThumbnail(thumbnails);

  int get trackCount => numberOfTracks ?? tracks.length;

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      albumId: Json.strOr(json['album_id'] ?? json['id'], ''),
      title: Json.strOr(json['title'], 'Desconocido'),
      artist: Json.str(json['artist'] ?? json['artist_name']),
      artistId: Json.str(json['artist_id']),
      releaseDate: Json.str(json['release_date']),
      numberOfTracks: Json.asInt(json['number_of_tracks'] ?? json['track_count']),
      durationSeconds: Json.asInt(json['duration_seconds']),
      thumbnails: Thumbnail.listFrom(json['thumbnails'] ?? json['images']),
      tracks: Json.listAt(json, 'tracks').map(Track.fromJson).toList(growable: false),
      copyright: Json.str(json['copyright']),
      upc: Json.str(json['upc']),
    );
  }

  Map<String, dynamic> toJson() => {
        'album_id': albumId,
        'title': title,
        if (artist != null) 'artist': artist,
        if (artistId != null) 'artist_id': artistId,
        if (releaseDate != null) 'release_date': releaseDate,
        if (numberOfTracks != null) 'number_of_tracks': numberOfTracks,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        'thumbnails': thumbnails.map((t) => t.toJson()).toList(),
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };
}
