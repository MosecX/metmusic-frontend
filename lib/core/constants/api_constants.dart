/// Constantes de configuración del backend MetMusic.
///
/// El backend es un intermediario autohospedado entre la app y los
/// proveedores de música (Tidal para metadatos, Qobuz para stream primario).
class ApiConstants {
  ApiConstants._();

  /// URL base por defecto del backend.
  static const String baseUrl = 'https://tdl-qbz-api.metmusic.qzz.io';

  /// Token Bearer precargado. El usuario puede cambiarlo desde Settings.
  static const String defaultApiToken =
      '7b9f86c70e56a3a6c35d08f3d4798c6147972aa7cdd6a5c86dbc388b2d66b429';

  /// Timeouts (milisegundos).
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 15000;

  /// Prefijo obligatorio de todos los endpoints que requieren auth.
  static const String apiPrefix = '/api';

  /// Endpoint de salud (NO requiere auth).
  static const String health = '$apiPrefix/health';

  /// Ruta base de la API.
  static String get baseApiPath => apiPrefix;
}

/// Parámetros de calidad de audio soportados por el selector de Settings.
enum AudioQualityPreference {
  /// Máxima calidad disponible.
  best('best', 'Máxima (HI_RES / FLAC)'),

  /// Calidad media.
  medium('medium', 'Media (LOSSLESS / CD)'),

  /// Calidad baja.
  low('low', 'Baja (ahorro de datos)');

  const AudioQualityPreference(this.value, this.label);

  /// Valor enviado como query param al backend.
  final String value;

  /// Etiqueta legible.
  final String label;
}
