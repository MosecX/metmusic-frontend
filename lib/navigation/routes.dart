/// Rutas tipadas de la app.
///
/// Para agregar una pantalla nueva solo hay que añadir la constante aquí y
/// registrarla en `app_router.dart`.
class Routes {
  Routes._();

  // --- Shell (bottom nav) ---
  static const String home = '/home';
  static const String search = '/search';
  static const String library = '/library';
  static const String settings = '/settings';

  // --- Fuera del shell ---
  static const String player = '/player';

  static const String album = '/album/:albumId';
  static const String artist = '/artist/:artistId';
  static const String playlist = '/playlist/:playlistId';
  static const String userPlaylist = '/user-playlist/:playlistId';
  static const String mix = '/mix/:trackId';

  // --- Nombres (para navegación tipada) ---
  static const String homeName = 'home';
  static const String searchName = 'search';
  static const String libraryName = 'library';
  static const String settingsName = 'settings';
  static const String playerName = 'player';
  static const String albumName = 'album';
  static const String artistName = 'artist';
  static const String playlistName = 'playlist';
  static const String userPlaylistName = 'userPlaylist';
  static const String mixName = 'mix';

  // --- Índice de la bottom nav ---
  static const List<String> shellPaths = [home, search, library, settings];

  static int indexOf(String location) {
    for (var i = 0; i < shellPaths.length; i++) {
      if (location.startsWith(shellPaths[i])) return i;
    }
    return 0;
  }

  // --- Builders ---
  static String albumPath(String albumId) => '/album/$albumId';

  static String artistPath(String artistId) => '/artist/$artistId';

  static String playlistPath(String playlistId) => '/playlist/$playlistId';

  static String userPlaylistPath(String playlistId) =>
      '/user-playlist/$playlistId';

  static String mixPath(String trackId) => '/mix/$trackId';
}
