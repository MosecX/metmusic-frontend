import '../utils/extensions.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';
import 'track.dart';

/// Tipo de búsqueda soportado por `/api/search`.
enum SearchType {
  all('all', 'Todo'),
  tracks('tracks', 'Canciones'),
  albums('albums', 'Álbumes'),
  artists('artists', 'Artistas'),
  playlists('playlists', 'Playlists');

  const SearchType(this.value, this.label);

  final String value;
  final String label;
}

/// Respuesta de `GET /api/search`.
class SearchResults {
  const SearchResults({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.totalResults = 0,
    this.query = '',
  });

  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;
  final int totalResults;
  final String query;

  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;

  int get count =>
      tracks.length + albums.length + artists.length + playlists.length;

  factory SearchResults.fromJson(Map<String, dynamic> json, {String query = ''}) {
    return SearchResults(
      tracks: Json.listAt(json, 'tracks').map(Track.fromJson).toList(growable: false),
      albums: Json.listAt(json, 'albums').map(Album.fromJson).toList(growable: false),
      artists:
          Json.listAt(json, 'artists').map(Artist.fromJson).toList(growable: false),
      playlists: Json.listAt(json, 'playlists')
          .map(Playlist.fromJson)
          .toList(growable: false),
      totalResults: Json.intOr(json['total_results'], 0),
      query: query,
    );
  }

  static const SearchResults empty = SearchResults();
}
