import 'dart:async';
import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../app.dart';
import '../core/constants/api_constants.dart';
import '../core/models/stream_info.dart';
import '../core/models/track.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../features/player/audio/metmusic_audio_handler.dart';
import '../services/api/stream_service.dart';
import '../services/local/favorites_service.dart';
import '../services/local/history_service.dart';
import '../services/local/mix_favorites_service.dart';
import '../services/local/settings_storage.dart';
import '../services/service_providers.dart';

/// Buffer de errores para poder mostrarlos **dentro** de la app.
///
/// En release no se ve la consola sin `adb logcat`, así que cualquier fallo
/// queda registrado acá y se dibuja en pantalla.
class AppDiagnostics {
  AppDiagnostics._();

  static final List<String> _entries = <String>[];
  static final Map<String, String> _runtime = <String, String>{};

  static List<String> get entries => List.unmodifiable(_entries);

  /// Notas del arranque (por ejemplo, audio en modo degradado).
  static Map<String, String> get runtime => Map.unmodifiable(_runtime);

  static String get summary => _entries.isEmpty ? '' : _entries.join('\n\n');

  /// Instala los handlers globales. Debe llamarse justo después de
  /// `WidgetsFlutterBinding.ensureInitialized()`.
  static void install() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      _record('FlutterError', details.exceptionAsString(), details.stack);
      previousOnError?.call(details);
    };

    // Evita que una excepción no capturada cierre la app sin dejar rastro.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _record('onError', error.toString(), stack);
      return true;
    };

    // En release Flutter dibuja un cuadro gris vacío: lo reemplazamos por una
    // superficie con el mensaje real del error.
    ErrorWidget.builder = (FlutterErrorDetails details) =>
        AppErrorSurface(message: details.exceptionAsString());
  }

  static void note(String key, String value) {
    _runtime[key] = value;
    _record('Info', '$key: $value', null);
  }

  /// Registra un error con su origen.
  static void record(String origin, String message, [StackTrace? stack]) =>
      _record(origin, message, stack);

  static void _record(String origin, String message, StackTrace? stack) {
    final head = (stack?.toString().split('\n') ?? const <String>[])
        .take(6)
        .where((l) => l.trim().isNotEmpty)
        .join('\n');
    final entry = '[$origin] $message${head.isEmpty ? '' : '\n$head'}';
    _entries.add(entry);
    debugPrint('MetMusic $entry');
    if (_entries.length > 20) _entries.removeAt(0);
  }
}

/// Superficie de error legible, usable como reemplazo de `ErrorWidget.builder`.
///
/// Se envuelve en `Material` + `DefaultTextStyle` porque este widget se dibuja
/// *en lugar* del widget que falló y puede quedar sin ancestro de texto: sin
/// eso Flutter usa `_errorTextStyle` y todos los textos salen subrayados en
/// amarillo.
class AppErrorSurface extends StatelessWidget {
  const AppErrorSurface({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          color: AppColors.textPrimary,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(16),
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MetMusic encontró un error',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Resultado del arranque: dependencias ya abiertas.
class BootResult {
  const BootResult({
    required this.settings,
    required this.history,
    required this.favorites,
    required this.mixFavorites,
    required this.baseUrl,
    required this.token,
    required this.client,
    required this.audioHandler,
  });

  final SettingsStorage settings;
  final HistoryService history;
  final FavoritesService favorites;
  final MixFavoritesService mixFavorites;
  final BaseUrlHolder baseUrl;
  final ApiTokenHolder token;
  final ApiClient client;
  final MetMusicAudioHandler audioHandler;
}

/// Ejecuta la inicialización por pasos.
///
/// Cada paso abre **una** dependencia y devuelve el error con el nombre del
/// paso, para que la UI pueda mostrar exactamente dónde se rompió.
Future<BootResult> bootApp() async {
  final steps = <String>[];

  // 1. Hive.
  try {
    await Hive.initFlutter();
  } catch (error, stack) {
    _fail('Almacenamiento local (Hive)', error, stack);
  }

  // 2. SharedPreferences.
  final SettingsStorage settings;
  try {
    settings = await SettingsStorage.create();
  } catch (error, stack) {
    _fail('Preferencias (SharedPreferences)', error, stack);
  }

  // 3. Cajas de Hive (historial, favoritos).
  final HistoryService history;
  final FavoritesService favorites;
  final MixFavoritesService mixFavorites;
  try {
    history = await HistoryService.open();
    favorites = await FavoritesService.open();
    mixFavorites = await MixFavoritesService.open();
  } catch (error, stack) {
    _fail('Cajas de Hive (historial/favoritos)', error, stack);
  }

  // 4. Red.
  final baseUrl = BaseUrlHolder(settings.baseUrl);
  final token = ApiTokenHolder(settings.apiToken);
  final ApiClient client;
  try {
    client = ApiClient(baseUrl: baseUrl, token: token);
  } catch (error, stack) {
    _fail('Cliente HTTP (Dio)', error, stack);
  }

  // 5. Audio. Si `AudioService.init` falla (MediaSession del sistema,
  // notificación, etc.) se degrada a un handler sin sesión de medios: la app
  // sigue reproduciendo, sólo se pierde la notificación/Bluetooth.
  final handler =
      await _initAudio(settings: settings, client: client, steps: steps);

  for (final step in steps) {
    AppDiagnostics.note('init', step);
  }

  return BootResult(
    settings: settings,
    history: history,
    favorites: favorites,
    mixFavorites: mixFavorites,
    baseUrl: baseUrl,
    token: token,
    client: client,
    audioHandler: handler,
  );
}

/// Inicializa el handle de audio, degradando si la MediaSession falla.
Future<MetMusicAudioHandler> _initAudio({
  required SettingsStorage settings,
  required ApiClient client,
  required List<String> steps,
}) async {
  final streamService = StreamService(client);

  Future<StreamInfo> resolve(Track track) {
    return streamService.getStream(
      track.trackId,
      quality: settings.audioQuality,
    );
  }

  try {
    final handler = await AudioService.init(
      builder: () => MetMusicAudioHandler(resolveStream: resolve),
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
    steps.add('MediaSession activa');
    return handler;
  } catch (error, stack) {
    AppDiagnostics.record(
      'Audio degradado',
      'Sin sesión de medios (no habrá notificación ni controles Bluetooth): '
          '$error',
      stack,
    );
    steps.add('Audio sin MediaSession');
    return MetMusicAudioHandler(resolveStream: resolve);
  }
}

Never _fail(String step, Object error, StackTrace stack) {
  AppDiagnostics.record('Arranque fallido', '$step → $error', stack);
  throw BootFailure(step, error, stack);
}

/// Error de arranque con el paso que lo provocó.
class BootFailure implements Exception {
  BootFailure(this.step, this.error, this.stack);

  final String step;
  final Object error;
  final StackTrace stack;

  @override
  String toString() => 'Falló "$step": $error';
}

/// Raíz de la app.
///
/// Arranca **siempre**: primero muestra una pantalla de carga (o de error) y
/// recién cuando las dependencias están listas monta el `ProviderContainer`
/// raíz (vía `UncontrolledProviderScope`) con el `MaterialApp.router`. Así nunca
/// queda una pantalla en blanco y cualquier problema de arranque se ve en el
/// dispositivo.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  /// Contenedor raíz con los overrides. Se crea **después** del arranque y se
  /// expone con `UncontrolledProviderScope` en vez de anidar otro
  /// `ProviderScope`, para que no quede ninguna ambigüedad sobre qué
  /// contenedor lee cada widget.
  ProviderContainer? _container;
  BootFailure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final result = await bootApp();
      if (!mounted) return;

      // Contenedor raíz único, creado con todos los overrides.
      final container = ProviderContainer(
        overrides: [
          settingsStorageProvider.overrideWithValue(result.settings),
          historyServiceProvider.overrideWithValue(result.history),
          favoritesServiceProvider.overrideWithValue(result.favorites),
          mixFavoritesServiceProvider.overrideWithValue(result.mixFavorites),
          baseUrlHolderProvider.overrideWithValue(result.baseUrl),
          apiTokenHolderProvider.overrideWithValue(result.token),
          apiClientProvider.overrideWithValue(result.client),
          audioHandlerProvider.overrideWithValue(result.audioHandler),
        ],
      );

      final previous = _container;
      setState(() {
        _container = container;
        _loading = false;
      });
      // Se destruye recién después de que el árbol ya no lo referencia.
      previous?.dispose();
    } on BootFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _failure = failure;
        _loading = false;
      });
    } catch (error, stack) {
      AppDiagnostics.record('Arranque', error.toString(), stack);
      if (!mounted) return;
      setState(() {
        _failure = BootFailure('arranque', error, stack);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const MetMusicApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: _loading
          ? const _BootLoading()
          : _BootError(failure: _failure, onRetry: _boot),
    );
  }
}

class _BootLoading extends StatelessWidget {
  const _BootLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 18),
            Text('MetMusic', style: AppTextStyles.headline),
            SizedBox(height: 6),
            Text('Iniciando…', style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.failure, required this.onRetry});

  final BootFailure? failure;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final step = failure?.step ?? 'desconocido';
    final error = failure?.error.toString() ?? 'Error desconocido';
    final head = (failure?.stack.toString().split('\n') ?? const <String>[])
        .take(8)
        .where((l) => l.trim().isNotEmpty)
        .join('\n');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No se pudo iniciar MetMusic',
                  style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text('Paso: $step', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      '$error\n\n$head',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Backend por defecto: ${ApiConstants.baseUrl}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
