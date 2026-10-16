import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../services/api/health_service.dart';
import '../../../services/service_providers.dart';

/// Estado de configuración de la app.
class SettingsState {
  const SettingsState({
    required this.baseUrl,
    required this.apiToken,
    required this.audioQuality,
  });

  final String baseUrl;
  final String apiToken;
  final AudioQualityPreference audioQuality;

  bool get hasCustomToken => apiToken != ApiConstants.defaultApiToken;
  bool get hasCustomBaseUrl => baseUrl != ApiConstants.baseUrl;

  SettingsState copyWith({
    String? baseUrl,
    String? apiToken,
    AudioQualityPreference? audioQuality,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      apiToken: apiToken ?? this.apiToken,
      audioQuality: audioQuality ?? this.audioQuality,
    );
  }
}

/// Controlador de Settings. Actualiza SharedPreferences y los holders de red
/// para que el [ApiClient] use los valores nuevos de inmediato.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._ref)
      : super(
          SettingsState(
            baseUrl: _ref.read(settingsStorageProvider).baseUrl,
            apiToken: _ref.read(settingsStorageProvider).apiToken,
            audioQuality: _ref.read(settingsStorageProvider).audioQuality,
          ),
        );

  final Ref _ref;

  /// Persiste la URL del backend y reinicia el cliente HTTP.
  Future<void> setBaseUrl(String url) async {
    final storage = _ref.read(settingsStorageProvider);
    await storage.setBaseUrl(url);
    _ref.read(baseUrlHolderProvider).update(storage.baseUrl);
    state = state.copyWith(baseUrl: _ref.read(baseUrlHolderProvider).value);
    _ref.invalidate(connectivityProvider);
  }

  /// Persiste el token Bearer.
  Future<void> setApiToken(String token) async {
    final storage = _ref.read(settingsStorageProvider);
    await storage.setApiToken(token);
    _ref.read(apiTokenHolderProvider).update(storage.apiToken);
    state = state.copyWith(apiToken: _ref.read(apiTokenHolderProvider).value);
  }

  /// Restaura el token precargado por defecto.
  Future<void> resetToken() => setApiToken(ApiConstants.defaultApiToken);

  /// Restaura la URL del backend por defecto.
  Future<void> resetBaseUrl() => setBaseUrl(ApiConstants.baseUrl);

  /// Cambia la calidad de audio preferida (se envía como query param).
  Future<void> setAudioQuality(AudioQualityPreference quality) async {
    await _ref.read(settingsStorageProvider).setAudioQuality(quality);
    state = state.copyWith(audioQuality: quality);
  }

  /// `GET /api/health` para el botón "Probar conexión".
  Future<HealthStatus> testConnection() {
    return _ref.read(healthServiceProvider).check();
  }

  /// `DELETE /api/cache` — limpia la caché del servidor.
  Future<void> clearServerCache() {
    return _ref.read(healthServiceProvider).clearServerCache();
  }
}

/// Configuración actual.
final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref);
});

/// Calidad de audio seleccionada.
final audioQualityProvider = Provider<AudioQualityPreference>((ref) {
  return ref.watch(settingsProvider.select((s) => s.audioQuality));
});

/// Estado del test de conexión (idle / loading / data / error).
final connectionTestProvider =
    StateProvider<AsyncValue<HealthStatus>?>((ref) => null);

/// `GET /api/health` — estado de los servicios del backend para la sección
/// "Estado de los servicios" de Ajustes (se refetchea al revalidar).
final apiHealthProvider = FutureProvider.autoDispose<HealthStatus>((ref) {
  return ref.watch(healthServiceProvider).check();
});
