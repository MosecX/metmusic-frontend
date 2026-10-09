/// Constantes generales de la aplicación.
class AppConstants {
  AppConstants._();

  static const String appName = 'MetMusic';
  static const String appVersion = '0.1.0+1';

  // --- Claves de SharedPreferences ---
  static const String prefBaseUrl = 'pref_base_url';
  static const String prefApiToken = 'pref_api_token';
  static const String prefAudioQuality = 'pref_audio_quality';
  static const String prefLyricsMode = 'pref_lyrics_mode';
  static const String prefShuffle = 'pref_shuffle';
  static const String prefRepeatMode = 'pref_repeat_mode';

  // --- Hive ---
  static const String hiveBoxHistory = 'history';
  static const String hiveBoxFavorites = 'favorites';
  static const String hiveBoxPlaylists = 'user_playlists';
  static const String hiveBoxCache = 'api_cache';

  // --- UI ---
  static const double radius = 20;
  static const double glassBlur = 20;
  static const double pagePadding = 16;
  static const double sectionGap = 24;
  static const double itemGap = 12;
  static const double miniPlayerHeight = 64;
  static const double navBarHeight = 68;

  /// Padding inferior del `MiniPlayer` dentro del `bottomNavigationBar`.
  ///
  /// El contenido de las pantallas lo necesita para no quedar tapado cuando hay
  /// reproducción (por ejemplo, el botón "Nueva" de la biblioteca).
  static const double miniPlayerBottomGap = 8;

  /// Padding inferior de las listas dentro del shell: barra de navegación +
  /// mini player + margen de respiración (68 + 64 + 8 + 20 = 160). Único
  /// valor para que todas las pantallas terminen a la misma altura.
  static const double shellBottomInset =
      navBarHeight + miniPlayerHeight + miniPlayerBottomGap + 20;

  // --- Búsqueda ---
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Tag de la animación Hero compartida entre MiniPlayer y FullPlayer.
  static const String heroArtworkTag = 'metmusic-player-artwork';

  // --- Reproducción ---
  static const Duration resumeRewind = Duration(seconds: 10);
  static const int historyFlushSeconds = 10;
  static const int defaultSearchLimit = 30;
  static const int favoritesPageSize = 200;
}

/// Modo de presentación de las letras (estándar o visualizer).
enum LyricsMode {
  standard('standard', 'Estándar'),
  visualizer('visualizer', 'Visualizer');

  const LyricsMode(this.value, this.label);

  /// Valor persistido en SharedPreferences.
  final String value;
  final String label;

  static LyricsMode fromValue(String? raw) => LyricsMode.values.firstWhere(
        (mode) => mode.value == raw,
        orElse: () => LyricsMode.standard,
      );
}
