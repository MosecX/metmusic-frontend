import '../utils/extensions.dart';
import '../utils/image_utils.dart';
import 'thumbnail.dart';
import 'track.dart';

/// Playlist (editorial o de usuario). Sirve para resumen y detalle.
class Playlist {
  const Playlist({
    required this.playlistId,
    required this.title,
    this.creator,
    this.description,
    this.numberOfTracks,
    this.thumbnails = const [],
    this.tracks = const [],
  });

  final String playlistId;
  final String title;
  final String? creator;
  final String? description;
  final int? numberOfTracks;
  final List<Thumbnail> thumbnails;
  final List<Track> tracks;

  String get thumbnailUrl => ImageUtils.cardThumbnail(thumbnails);

  int get trackCount => numberOfTracks ?? tracks.length;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      playlistId: Json.strOr(
        json['playlist_id'] ?? json['uuid'] ?? json['id'],
        '',
      ),
      title: Json.strOr(json['title'] ?? json['name'], 'Sin título'),
      creator: Json.str(json['creator'] ?? json['owner']),
      description: Json.str(json['description']),
      numberOfTracks:
          Json.asInt(json['number_of_tracks'] ?? json['track_count']),
      thumbnails: Thumbnail.listFrom(json['thumbnails'] ?? json['images']),
      tracks: Json.listAt(json, 'tracks')
          .map(Track.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'playlist_id': playlistId,
        'title': title,
        if (creator != null) 'creator': creator,
        if (description != null) 'description': description,
        if (numberOfTracks != null) 'number_of_tracks': numberOfTracks,
        'thumbnails': thumbnails.map((t) => t.toJson()).toList(),
        'tracks': tracks.map((t) => t.toJson()).toList(),
      };
}
