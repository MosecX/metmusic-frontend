import '../utils/extensions.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';
import 'track.dart';

/// Tipo de contenido de una sección de Explore.
enum ExploreSectionType {
  tracks('tracks'),
  albums('albums'),
  artists('artists'),
  playlists('playlists'),
  unknown('unknown');

  const ExploreSectionType(this.value);

  final String value;

  static ExploreSectionType parse(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'tracks':
      case 'songs':
      case 'charts':
        return ExploreSectionType.tracks;
      case 'albums':
      case 'releases':
      case 'new_releases':
        return ExploreSectionType.albums;
      case 'artists':
        return ExploreSectionType.artists;
      case 'playlists':
        return ExploreSectionType.playlists;
      default:
        return ExploreSectionType.unknown;
    }
  }
}

/// Una fila de la Home (carrusel de álbumes, lista de tracks, etc.).
class ExploreSection {
  const ExploreSection({
    required this.id,
    required this.title,
    required this.type,
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  final String id;
  final String title;
  final ExploreSectionType type;
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;

  /// Parsea una sección de forma tolerante.
  ///
  /// Acepta `{title, type, items}` o directamente una lista de items; en el
  /// segundo caso el tipo se infiere del contenido.
  factory ExploreSection.fromJson(String key, dynamic value) {
    String title = _humanize(key);
    var type = ExploreSectionType.parse(key);

    List<Map<String, dynamic>> items;
    if (value is List) {
      items = Json.maps(value);
    } else if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      title = Json.strOr(map['title'] ?? map['name'] ?? map['heading'], title);
      type = ExploreSectionType.parse(
        Json.str(map['type'] ?? map['section_type']) ?? key,
      );
      final raw = map['items'] ??
          map['tracks'] ??
          map['albums'] ??
          map['artists'] ??
          map['playlists'] ??
          map['data'] ??
          const <dynamic>[];
      items = Json.maps(raw);
      if (map['tracks'] != null) type = ExploreSectionType.tracks;
      if (map['albums'] != null) type = ExploreSectionType.albums;
      if (map['artists'] != null) type = ExploreSectionType.artists;
      if (map['playlists'] != null) type = ExploreSectionType.playlists;
    } else {
      return ExploreSection(
        id: key,
        title: title,
        type: ExploreSectionType.unknown,
      );
    }

    if (type == ExploreSectionType.unknown && items.isNotEmpty) {
      type = _detectType(items.first);
    }

    return ExploreSection(
      id: key,
      title: title,
      type: type,
      tracks: type == ExploreSectionType.tracks
          ? items.map(Track.fromJson).toList(growable: false)
          : const [],
      albums: type == ExploreSectionType.albums
          ? items.map(Album.fromJson).toList(growable: false)
          : const [],
      artists: type == ExploreSectionType.artists
          ? items.map(Artist.fromJson).toList(growable: false)
          : const [],
      playlists: type == ExploreSectionType.playlists
          ? items.map(Playlist.fromJson).toList(growable: false)
          : const [],
    );
  }

  static ExploreSectionType _detectType(Map<String, dynamic> item) {
    if (item.containsKey('track_id') || item.containsKey('isrc')) {
      return ExploreSectionType.tracks;
    }
    if (item.containsKey('album_id')) return ExploreSectionType.albums;
    if (item.containsKey('artist_id')) return ExploreSectionType.artists;
    if (item.containsKey('playlist_id') || item.containsKey('uuid')) {
      return ExploreSectionType.playlists;
    }
    if (item.containsKey('duration_seconds')) return ExploreSectionType.tracks;
    return ExploreSectionType.unknown;
  }

  static String _humanize(String key) {
    final spaced = key.replaceAll('_', ' ').trim();
    if (spaced.isEmpty) return 'Explorar';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

/// Contenido completo de la Home.
class ExploreHome {
  const ExploreHome({this.sections = const []});

  final List<ExploreSection> sections;

  bool get isEmpty => sections.every((s) => s.isEmpty);

  /// Tolerante: acepta `{sections: [...]}` o un mapa de listas.
  factory ExploreHome.fromJson(dynamic raw) {
    if (raw is List) {
      final sections = <ExploreSection>[];
      for (var i = 0; i < raw.length; i++) {
        final entry = raw[i];
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          final id = Json.strOr(map['id'] ?? map['key'], 'section_$i');
          sections.add(ExploreSection.fromJson(id, entry));
        } else if (entry is List) {
          sections.add(ExploreSection.fromJson('section_$i', entry));
        }
      }
      return ExploreHome(sections: sections.where((s) => !s.isEmpty).toList());
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final explicit = map['sections'];
      if (explicit is List) {
        final home = ExploreHome.fromJson(explicit);
        if (!home.isEmpty) return home;
      }
      // Ignorar claves de metadatos.
      const skip = {'total_results', 'total', 'count', 'limit', 'offset'};
      final sections = <ExploreSection>[];
      for (final entry in map.entries) {
        if (skip.contains(entry.key)) continue;
        if (entry.value is! List && entry.value is! Map) continue;
        final section = ExploreSection.fromJson(entry.key, entry.value);
        if (!section.isEmpty) sections.add(section);
      }
      return ExploreHome(sections: sections);
    }

    return const ExploreHome();
  }
}
