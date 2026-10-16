import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

/// Persistencia de ajustes con SharedPreferences.
class SettingsStorage {
  SettingsStorage(this._prefs);

  final SharedPreferences _prefs;

  /// Debe llamarse una vez en `main()` antes de crear el ProviderScope.
  static Future<SettingsStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsStorage(prefs);
  }

  // --- Servidor ---
  String get baseUrl =>
      _prefs.getString(AppConstants.prefBaseUrl) ?? ApiConstants.baseUrl;

  Future<void> setBaseUrl(String value) =>
      _prefs.setString(AppConstants.prefBaseUrl, value.trim());

  // --- Token ---
  String get apiToken =>
      _prefs.getString(AppConstants.prefApiToken) ??
      ApiConstants.defaultApiToken;

  Future<void> setApiToken(String value) =>
      _prefs.setString(AppConstants.prefApiToken, value.trim());

  // --- Calidad ---
  AudioQualityPreference get audioQuality {
    final raw = _prefs.getString(AppConstants.prefAudioQuality);
    return AudioQualityPreference.values.firstWhere(
      (q) => q.value == raw,
      orElse: () => AudioQualityPreference.best,
    );
  }

  Future<void> setAudioQuality(AudioQualityPreference quality) =>
      _prefs.setString(AppConstants.prefAudioQuality, quality.value);

  // --- Preferencias de reproducción ---
  bool get shuffle => _prefs.getBool(AppConstants.prefShuffle) ?? false;

  Future<void> setShuffle(bool value) =>
      _prefs.setBool(AppConstants.prefShuffle, value);

  int get repeatModeIndex => _prefs.getInt(AppConstants.prefRepeatMode) ?? 0;

  Future<void> setRepeatModeIndex(int value) =>
      _prefs.setInt(AppConstants.prefRepeatMode, value);
}
