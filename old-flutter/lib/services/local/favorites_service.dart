import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/track.dart';

/// Favoritos locales (Hive), espejo de `GET /api/user/favorites`.
///
/// La app escribe primero en local (respuesta instantánea) y luego sincroniza
/// con el backend; si no hay red, el estado local se conserva.
class FavoritesService {
  FavoritesService(this._box);

  final Box<dynamic> _box;

  static const String boxName = AppConstants.hiveBoxFavorites;

  static Future<FavoritesService> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return FavoritesService(box);
  }

  bool isFavorite(String trackId) => _box.containsKey(trackId);

  Set<String> get ids => _box.keys.map((e) => e.toString()).toSet();

  Future<void> add(Track track) async {
    await _box.put(track.trackId, track.toJson());
  }

  Future<void> remove(String trackId) async {
    await _box.delete(trackId);
  }

  /// Alterna el estado y devuelve el nuevo valor (true = favorito).
  Future<bool> toggle(Track track) async {
    if (isFavorite(track.trackId)) {
      await remove(track.trackId);
      return false;
    }
    await add(track);
    return true;
  }

  List<Track> getAll() => _box.values
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
      .toList(growable: false);

  /// Reemplaza el contenido local con la lista del servidor.
  Future<void> replaceAll(List<Track> tracks) async {
    await _box.clear();
    for (final track in tracks) {
      await _box.put(track.trackId, track.toJson());
    }
  }

  Future<void> clear() => _box.clear();

  int get length => _box.length;
}
