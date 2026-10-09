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
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtZXRtdXNpYy1hZG1pbi10b2tlbiIsIm5hbWUiOiJUT0tFTiIsInJvbGUiOiJhZG1pbiIsImFwcCI6Im1ldG11c2ljLWFuZHJvaWQiLCJ2ZXJzaW9uIjoiMS4wLjAiLCJwZXJtaXNzaW9ucyI6WyJzdHJlYW0iLCJzZWFyY2giLCJtZXRhZGF0YSIsInBsYXlsaXN0cyIsImhpc3RvcnkiLCJmYXZvcml0ZXMiLCJseXJpY3MiLCJjYW52YXMiLCJleHBsb3JlIl0sImRldmljZV9pZCI6ImEzZjhjMmQxZTViNzA5NDRmNmIyYThkOWMxZTNmNWE3YjlkMGUyZjRhNjhiMGMyZDRlNmY4YTBiMmM0ZDZlOGYwIiwic2Vzc2lvbl9pZCI6IjFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzIiwiaXNzdWVkX2J5IjoibWV0bXVzaWMtYmFja2VuZCIsInNjb3BlIjoiZnVsbF9hY2Nlc3MiLCJ0aWVyIjoiaGlyZXMiLCJtYXhfcXVhbGl0eSI6IkhJX1JFUyIsInByb3ZpZGVycyI6WyJxb2J1eiIsInRpZGFsIl0sImZlYXR1cmVzIjpbInN0cmVhbWluZyIsIm9mZmxpbmUiLCJseXJpY3Nfc3luYyIsImNhbnZhcyIsImVxdWFsaXplciIsInNjcm9iYmxpbmciXSwiaWF0IjoxNzUwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTksIm5iZiI6MTc1MDAwMDAwMCwianRpIjoiNGY1YTZiN2M4ZDllMGYxZjJhM2I0YzVkNmU3ZjgwOTFhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjAiLCJhdWQiOiJ0ZGwtcWJ6LWFwaS5tZXRtdXNpYy5xenouaW8iLCJpc3MiOiJtZXRtdXNpYy1hdXRoIiwiZXh0cmFfZGF0YSI6eyJyZWdpb24iOiJMQVRBTSIsImxhbmd1YWdlIjoiZXMiLCJ0aGVtZSI6ImRhcmsiLCJhdWRpb19jb2RlY19wcmVmZXJlbmNlIjpbImZsYWMiLCJtcDQiLCJvcHVzIl0sIm1heF9iaXRyYXRlIjo5MjE2LCJzYW1wbGVfcmF0ZXMiOls0NDEwMCw0ODAwMCw5NjAwMCwxOTIwMDBdLCJiaXRfZGVwdGhzIjpbMTYsMjQsMzJdLCJjYW52YXNfZW5hYmxlZCI6dHJ1ZSwic2VnbWVudF9wcm94eSI6ZmFsc2UsImNhY2hlX3R0bCI6MzYwMCwic2Vzc2lvbl90b2tlbiI6ImUxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMTJiM2M0ZDVlNmY3YThiOWMwZDFlMmYzYTRiNWM2ZDdlOGY5YTBiMWMyZDNlNGY1YTZiNyIsInJlZnJlc2hfdG9rZW4iOiIxZjJhM2I0YzVkNmU3ZjhhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzFkMmUzZjRhNWI2YzdkOGU5ZjBhMmIzYzRkNWU2ZjdhOWIwYzEiLCJhcGlfa2V5X2ludGVybmFsIjoiYTliOGM3ZDZlNWY0YTNiMmMxZDBlOWY4YTdiNmM1ZDRlM2YyYTFiMGM5ZDhlN2Y2YTViNGMzZDJlMWYwIn19.9rMELXs3SAFkQ6960Reln8keTY9fo9YgK5JcL7I1Kzw';

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
