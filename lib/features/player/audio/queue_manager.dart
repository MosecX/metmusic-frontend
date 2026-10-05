import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../../../core/models/track.dart';
import '../models/queue_state.dart';

/// Gestiona la lista de reproducción, el track actual, el shuffle y el repeat.
///
/// El shuffle se implementa con una permutación de índices ([_playOrder]) para
/// que "siguiente/anterior" siga un orden estable y visible en la QueueSheet.
class QueueManager {
  QueueManager({
    List<Track> tracks = const [],
    int currentIndex = -1,
    bool shuffle = false,
    LoopMode repeat = LoopMode.off,
  })  : _shuffle = shuffle,
        _repeat = repeat,
        _currentIndex = currentIndex {
    _tracks.addAll(tracks);
    _rebuildPlayOrder();
  }

  final List<Track> _tracks = [];
  List<int> _playOrder = [];
  int _currentIndex;
  bool _shuffle;
  LoopMode _repeat;
  final Random _random = Random();

  final StreamController<QueueState> _controller =
      StreamController<QueueState>.broadcast();

  // --- Lecturas ---

  Stream<QueueState> get stream => _controller.stream;

  List<Track> get tracks => List.unmodifiable(_tracks);

  int get currentIndex => _currentIndex;

  Track? get current =>
      (_currentIndex >= 0 && _currentIndex < _tracks.length)
          ? _tracks[_currentIndex]
          : null;

  bool get shuffle => _shuffle;

  LoopMode get repeat => _repeat;

  bool get isEmpty => _tracks.isEmpty;

  bool get hasNext {
    if (_tracks.isEmpty) return false;
    if (_repeat == LoopMode.all) return true;
    final pos = _playOrder.indexOf(_currentIndex);
    return pos >= 0 && pos < _playOrder.length - 1;
  }

  bool get hasPrevious {
    if (_tracks.isEmpty) return false;
    if (_repeat == LoopMode.all) return true;
    return _playOrder.indexOf(_currentIndex) > 0;
  }

  QueueState get state => QueueState(
        tracks: tracks,
        currentIndex: _currentIndex,
        shuffle: _shuffle,
        repeat: _repeat,
      );

  // --- Escrituras ---

  /// Reemplaza la cola completa y fija el índice inicial.
  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _tracks
      ..clear()
      ..addAll(tracks);
    _currentIndex = tracks.isEmpty ? -1 : startIndex.clamp(0, tracks.length - 1);
    _rebuildPlayOrder();
    _emit();
  }

  void addTrack(Track track, {bool next = false}) {
    if (next && _currentIndex >= 0 && _currentIndex < _tracks.length) {
      _tracks.insert(_currentIndex + 1, track);
      _currentIndex++; // el track actual se desplaza una posición
    } else {
      _tracks.add(track);
    }
    _rebuildPlayOrder();
    _emit();
  }

  void addTracks(List<Track> tracks) {
    if (tracks.isEmpty) return;
    _tracks.addAll(tracks);
    _rebuildPlayOrder();
    _emit();
  }

  /// Elimina el track en [index]. Devuelve true si se eliminó el track actual.
  bool removeAt(int index) {
    if (index < 0 || index >= _tracks.length) return false;
    final wasCurrent = index == _currentIndex;
    _tracks.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (wasCurrent) {
      _currentIndex = _currentIndex.clamp(0, max(_tracks.length - 1, 0));
    }
    if (_tracks.isEmpty) _currentIndex = -1;
    _rebuildPlayOrder();
    _emit();
    return wasCurrent;
  }

  /// Reordena la cola (drag & drop de la QueueSheet).
  void move(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _tracks.length) return;
    var target = newIndex;
    if (target < 0) target = 0;
    if (target >= _tracks.length) target = _tracks.length - 1;
    final track = _tracks.removeAt(oldIndex);
    _tracks.insert(target, track);

    if (_currentIndex == oldIndex) {
      _currentIndex = target;
    } else if (oldIndex < _currentIndex && target >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && target <= _currentIndex) {
      _currentIndex++;
    }
    _rebuildPlayOrder();
    _emit();
  }

  void clear() {
    _tracks.clear();
    _currentIndex = -1;
    _playOrder = [];
    _emit();
  }

  void setShuffle(bool value) {
    if (_shuffle == value) return;
    _shuffle = value;
    _rebuildPlayOrder();
    _emit();
  }

  void setRepeat(LoopMode mode) {
    if (_repeat == mode) return;
    _repeat = mode;
    _emit();
  }

  /// Avanza la posición del track actual (usado al cambiar de pista).
  void setCurrentIndex(int index) {
    if (index < 0 || index >= _tracks.length) return;
    if (_currentIndex == index) return;
    _currentIndex = index;
    _emit();
  }

  /// Siguiente índice según el orden de reproducción y el modo repeat.
  ///
  /// Devuelve `null` si no hay más y el repeat está desactivado.
  int? nextIndex({bool manual = false}) {
    if (_tracks.isEmpty) return null;
    if (_repeat == LoopMode.one && !manual) return _currentIndex;
    final pos = _playOrder.indexOf(_currentIndex);
    if (pos < 0) return _playOrder.isEmpty ? null : _playOrder.first;
    if (pos < _playOrder.length - 1) return _playOrder[pos + 1];
    if (_repeat == LoopMode.all) return _playOrder.first;
    return null;
  }

  /// Índice anterior según el orden de reproducción y el modo repeat.
  int? previousIndex() {
    if (_tracks.isEmpty) return null;
    final pos = _playOrder.indexOf(_currentIndex);
    if (pos > 0) return _playOrder[pos - 1];
    if (_repeat == LoopMode.all) return _playOrder.last;
    return null;
  }

  void dispose() => _controller.close();

  // --- Internos ---

  /// Reconstruye la permutación de reproducción.
  void _rebuildPlayOrder() {
    if (!_shuffle) {
      _playOrder = List<int>.generate(_tracks.length, (i) => i);
      return;
    }
    if (_tracks.isEmpty) {
      _playOrder = [];
      return;
    }
    final indices = List<int>.generate(_tracks.length, (i) => i)
      ..removeWhere((i) => i == _currentIndex);
    indices.shuffle(_random);
    // El track actual encabeza el orden para que "siguiente" sea coherente.
    _playOrder = [
      if (_currentIndex >= 0 && _currentIndex < _tracks.length) _currentIndex,
      ...indices,
    ];
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(state);
  }
}
