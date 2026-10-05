import '../utils/extensions.dart';
import 'thumbnail.dart';
import 'track.dart';

/// Playlist creada por el usuario (`/api/user/playlists`).
class UserPlaylist {
  const UserPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.trackCount,
    this.tracks = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final int? trackCount;
  final List<Track> tracks;
  final String? createdAt;
  final String? updatedAt;

  int get numberOfTracks => trackCount ?? tracks.length;

  factory UserPlaylist.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['playlist_id'] ?? json['uuid'];
    return UserPlaylist(
      id: rawId?.toString() ?? '',
      name: Json.strOr(json['name'] ?? json['title'], 'Sin título'),
      description: Json.str(json['description']),
      coverUrl: Json.str(json['cover_url'] ?? json['cover']),
      trackCount: Json.asInt(json['track_count'] ?? json['number_of_tracks']),
      tracks: Json.listAt(json, 'tracks').map(Track.fromJson).toList(growable: false),
      createdAt: Json.str(json['created_at']),
      updatedAt: Json.str(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'cover_url': coverUrl,
        if (trackCount != null) 'track_count': trackCount,
        'tracks': tracks.map((t) => t.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  UserPlaylist copyWith({
    String? name,
    String? description,
    String? coverUrl,
    int? trackCount,
    List<Track>? tracks,
  }) {
    return UserPlaylist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      trackCount: trackCount ?? this.trackCount,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static List<UserPlaylist> listFrom(dynamic value) => Json.maps(value)
      .map(UserPlaylist.fromJson)
      .toList(growable: false);

  /// Los thumbnails sintéticos derivan del cover_url local del usuario.
  List<Thumbnail> get syntheticThumbnails =>
      (coverUrl != null && coverUrl!.isNotEmpty) ? [Thumbnail(url: coverUrl!)] : const [];
}
