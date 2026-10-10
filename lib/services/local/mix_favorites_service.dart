import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/radio_mix.dart';

/// Mix (estación) guardado en favoritos locales.
class SavedMix {
  const SavedMix({required this.trackId, required this.mix});

  /// Pista semilla con la que se pide el radio (`/mix/{trackId}`).
  final String trackId;
  final RadioMix mix;
}

/// Favoritos de mixes locales (Hive), **sin** sync con el backend.
///
/// El guardado vive sólo en el teléfono: sirve para reabrir la página de la
/// estación desde la biblioteca sin tocar la API de usuario.
class MixFavoritesService {
  MixFavoritesService(this._box);

  final Box<dynamic> _box;

  static const String boxName = AppConstants.hiveBoxMixFavorites;

  static Future<MixFavoritesService> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return MixFavoritesService(box);
  }

  bool isFavorite(String trackId) => _box.containsKey(trackId);

  Set<String> get ids => _box.keys.map((e) => e.toString()).toSet();

  Future<void> add(String trackId, RadioMix mix) async {
    await _box.put(trackId, {
      'track_id': trackId,
      'mix': mix.toJson(),
    });
  }

  Future<void> remove(String trackId) async {
    await _box.delete(trackId);
  }

  /// Alterna el estado y devuelve el nuevo valor (true = favorito).
  Future<bool> toggle(String trackId, RadioMix mix) async {
    if (isFavorite(trackId)) {
      await remove(trackId);
      return false;
    }
    await add(trackId, mix);
    return true;
  }

  List<SavedMix> getAll() {
    final result = <SavedMix>[];
    for (final value in _box.values) {
      if (value is! Map) continue;
      final map = Map<dynamic, dynamic>.from(value);
      final trackId = map['track_id']?.toString() ?? '';
      final mix = map['mix'];
      if (trackId.isEmpty || mix is! Map) continue;
      result.add(
        SavedMix(
          trackId: trackId,
          mix: RadioMix.fromJson(Map<String, dynamic>.from(mix)),
        ),
      );
    }
    return result;
  }

  int get length => _box.length;
}
