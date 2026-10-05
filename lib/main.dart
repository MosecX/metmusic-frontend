import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/auth_interceptor.dart';
import 'features/player/audio/metmusic_audio_handler.dart';
import 'services/api/stream_service.dart';
import 'services/local/favorites_service.dart';
import 'services/local/history_service.dart';
import 'services/local/settings_storage.dart';
import 'services/service_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Almacenamiento local (Hive + SharedPreferences).
  await Hive.initFlutter();
  final settings = await SettingsStorage.create();
  final historyService = await HistoryService.open();
  final favoritesService = await FavoritesService.open();

  // 2. Red: los holders permiten cambiar URL/token en caliente desde Settings.
  final baseUrlHolder = BaseUrlHolder(settings.baseUrl);
  final tokenHolder = ApiTokenHolder(settings.apiToken);
  final apiClient = ApiClient(baseUrl: baseUrlHolder, token: tokenHolder);
  final streamService = StreamService(apiClient);

  // 3. Handles de audio: notificación, Bluetooth, Android Auto y wearables.
  final audioHandler = await AudioService.init(
    builder: () => MetMusicAudioHandler(
      resolveStream: (track) => streamService.getStream(
        track.trackId,
        quality: settings.audioQuality,
      ),
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'metmusic_playback',
      androidNotificationChannelName: 'MetMusic',
      androidNotificationChannelDescription:
          'Controles de reproducción de MetMusic',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
      androidShowNotificationBadge: false,
      androidResumeOnClick: false,
    ),
  );

  // 4. Inyección de dependencias.
  runApp(
    ProviderScope(
      overrides: [
        settingsStorageProvider.overrideWithValue(settings),
        historyServiceProvider.overrideWithValue(historyService),
        favoritesServiceProvider.overrideWithValue(favoritesService),
        baseUrlHolderProvider.overrideWithValue(baseUrlHolder),
        apiTokenHolderProvider.overrideWithValue(tokenHolder),
        apiClientProvider.overrideWithValue(apiClient),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MetMusicApp(),
    ),
  );
}
