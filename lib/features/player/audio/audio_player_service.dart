import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../../../core/models/stream_info.dart';

/// Wrapper delgado sobre `just_audio.AudioPlayer`.
///
/// Centraliza la construcción del [AudioSource] correcto según el
/// `manifest_type` resuelto por el backend:
/// - `dash` → [DashAudioSource]
/// - `direct` → progresivo ([AudioSource.uri])
class AudioPlayerService {
  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  AudioPlayer get player => _player;

  // --- Streams ---
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  // --- Lecturas sincrónicas ---
  bool get playing => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  Duration get bufferedPosition => _player.bufferedPosition;
  ProcessingState get processingState => _player.processingState;
  double get volume => _player.volume;
  double get speed => _player.speed;

  bool get isBuffering =>
      _player.processingState == ProcessingState.loading ||
      _player.processingState == ProcessingState.buffering;

  bool get isCompleted => _player.processingState == ProcessingState.completed;

  /// True cuando ya hay una fuente cargada y reproducible.
  bool get hasSource => _player.duration != null || _player.audioSource != null;

  /// Construye el [AudioSource] apropiado a partir del [StreamInfo].
  static AudioSource sourceFrom(StreamInfo info) {
    final uri = Uri.parse(info.url);
    if (info.isDash) {
      // DASH (Qobuz Hi-Res a veces entrega manifiesto): ExoPlayer lo resuelve.
      return DashAudioSource(uri);
    }
    return AudioSource.uri(uri);
  }

  /// Carga una URL de stream. Devuelve la duración reportada (puede ser null).
  Future<Duration?> setStream(
    StreamInfo info, {
    Duration initialPosition = Duration.zero,
    bool preload = true,
  }) async {
    await _player.setAudioSource(
      sourceFrom(info),
      initialPosition: initialPosition,
      preload: preload,
    );
    return _player.duration;
  }

  /// Carga una fuente arbitraria (usado en reintentos con URL refrescada).
  Future<Duration?> setRawSource(AudioSource source) async {
    await _player.setAudioSource(source);
    return _player.duration;
  }

  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    // No se await-ea: el future se completa recién al terminar la reproducción.
    unawaited(_player.play());
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double value) => _player.setVolume(value.clamp(0.0, 1.0));

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> setSpeed(double value) => _player.setSpeed(value);

  Future<void> dispose() => _player.dispose();
}
