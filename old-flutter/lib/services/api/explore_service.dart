import '../../core/models/album.dart';
import '../../core/models/explore.dart';
import '../../core/models/track.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// Moods soportados por `/api/explore/moods`.
enum ExploreMood {
  chill('chill', 'Chill'),
  workout('workout', 'Workout'),
  focus('focus', 'Focus'),
  party('party', 'Party');

  const ExploreMood(this.value, this.label);

  final String value;
  final String label;
}

/// Endpoints de exploración de la Home.
class ExploreService {
  ExploreService(this._client);

  final ApiClient _client;

  /// `GET /api/explore/home?mood={mood}`
  Future<ExploreHome> getHome({ExploreMood? mood}) async {
    final data = await _client.getJson(
      ApiEndpoints.exploreHome,
      query: mood == null ? null : {'mood': mood.value},
    );
    return ExploreHome.fromJson(data);
  }

  /// `GET /api/explore/new_releases?limit=&offset=`
  Future<List<Album>> getNewReleases({int limit = 20, int offset = 0}) async {
    final data = await _client.getJson(
      ApiEndpoints.exploreNewReleases,
      query: {'limit': limit, 'offset': offset},
    );
    return _albumsFrom(data);
  }

  /// `GET /api/explore/charts?limit=`
  Future<List<Track>> getCharts({int limit = 20}) async {
    final data = await _client.getJson(
      ApiEndpoints.exploreCharts,
      query: {'limit': limit},
    );
    return _tracksFrom(data);
  }

  /// `GET /api/explore/moods?mood={mood}&limit=`
  Future<List<Track>> getMood(
    ExploreMood mood, {
    int limit = 30,
  }) async {
    final data = await _client.getJson(
      ApiEndpoints.exploreMoods,
      query: {'mood': mood.value, 'limit': limit},
    );
    return _tracksFrom(data);
  }

  /// Extrae la primera lista de tracks de una respuesta heterogénea.
  List<Track> _tracksFrom(dynamic data) {
    if (data is List) return Json.maps(data).map(Track.fromJson).toList();
    final map = Json.mapOf(data);
    for (final key in ['tracks', 'items', 'results', 'charts', 'data']) {
      final value = map[key];
      if (value is List) {
        return Json.maps(value).map(Track.fromJson).toList(growable: false);
      }
    }
    return const [];
  }

  /// Extrae la primera lista de álbumes de una respuesta heterogénea.
  List<Album> _albumsFrom(dynamic data) {
    if (data is List) return Json.maps(data).map(Album.fromJson).toList();
    final map = Json.mapOf(data);
    for (final key in ['albums', 'items', 'results', 'new_releases', 'data']) {
      final value = map[key];
      if (value is List) {
        return Json.maps(value).map(Album.fromJson).toList(growable: false);
      }
    }
    return const [];
  }
}
