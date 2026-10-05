import '../utils/extensions.dart';
import '../utils/image_utils.dart';
import 'album.dart';
import 'thumbnail.dart';
import 'track.dart';

/// Artista. El mismo modelo sirve para resúmenes y detalle.
class Artist {
  const Artist({
    required this.artistId,
    required this.name,
    this.picture,
    this.bio,
    this.albums = const [],
    this.topTracks = const [],
    this.thumbnails = const [],
  });

  final String artistId;
  final String name;
  final String? picture;
  final String? bio;
  final List<Album> albums;
  final List<Track> topTracks;
  final List<Thumbnail> thumbnails;

  String get imageUrl {
    if (picture != null && picture!.isNotEmpty) return picture!;
    if (thumbnails.isNotEmpty) return ImageUtils.cardThumbnail(thumbnails);
    return '';
  }

  factory Artist.fromJson(Map<String, dynamic> json) {
    final rawPicture = json['picture'] ?? json['image'] ?? json['picture_url'];
    return Artist(
      artistId: Json.strOr(json['artist_id'] ?? json['id'], ''),
      name: Json.strOr(json['name'] ?? json['artist'], 'Desconocido'),
      picture: rawPicture is Map
          ? Json.str(rawPicture['url'])
          : Json.str(rawPicture),
      bio: Json.str(json['bio'] ?? json['description']),
      albums: Json.listAt(json, 'albums').map(Album.fromJson).toList(growable: false),
      topTracks: Json.listAt(json, 'tracks')
          .map(Track.fromJson)
          .toList(growable: false),
      thumbnails: Thumbnail.listFrom(json['thumbnails']),
    );
  }

  Map<String, dynamic> toJson() => {
        'artist_id': artistId,
        'name': name,
        if (picture != null) 'picture': picture,
        if (bio != null) 'bio': bio,
        'albums': albums.map((a) => a.toJson()).toList(),
        'tracks': topTracks.map((t) => t.toJson()).toList(),
      };
}
