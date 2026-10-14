/// Rutas tipadas del backend. Todos los paths incluyen el prefijo `/api`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String prefix = '/api';

  // --- Salud ---
  static const String health = '$prefix/health';

  // --- Búsqueda / catálogo ---
  static const String search = '$prefix/search';
  static String track(String trackId) => '$prefix/tracks/$trackId';
  static String stream(String trackId) => '$prefix/stream/$trackId';
  static String album(String albumId) => '$prefix/albums/$albumId';
  static String artist(String artistId) => '$prefix/artists/$artistId';
  static String playlist(String playlistUuid) =>
      '$prefix/playlists/$playlistUuid';
  static String lyrics(String trackId) => '$prefix/lyrics/$trackId';
  static String canvas(String trackId) => '$prefix/canvas/$trackId';
  static String radio(String trackId) => '$prefix/tracks/$trackId/radio';

  // --- Explore / Home ---
  static const String exploreHome = '$prefix/explore/home';
  static const String exploreNewReleases = '$prefix/explore/new_releases';
  static const String exploreCharts = '$prefix/explore/charts';
  static const String exploreMoods = '$prefix/explore/moods';

  // --- Playlists del usuario ---
  static const String userPlaylists = '$prefix/user/playlists';
  static String userPlaylist(String id) => '$prefix/user/playlists/$id';
  static String userPlaylistTracks(String id) =>
      '$prefix/user/playlists/$id/tracks';
  static String userPlaylistTrack(String id, String trackId) =>
      '$prefix/user/playlists/$id/tracks/$trackId';
  static String userPlaylistReorder(String id) =>
      '$prefix/user/playlists/$id/reorder';

  // --- Historial / Favoritos ---
  static const String userHistory = '$prefix/user/history';
  static String userFavorite(String trackId) =>
      '$prefix/user/favorites/$trackId';
  static const String userFavorites = '$prefix/user/favorites';
  static const String userFavoritesCheck = '$prefix/user/favorites/check';

  // --- Mantenimiento ---
  static const String cache = '$prefix/cache';
}
