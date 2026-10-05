import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/history_entry.dart';
import '../../core/utils/extensions.dart';

/// Historial de reproducción local (Hive). Permite mostrar la Library
/// sin conexión y actúa como caché de `GET /api/user/history`.
class HistoryService {
  HistoryService(this._box);

  final Box<dynamic> _box;

  static const String boxName = AppConstants.hiveBoxHistory;

  static Future<HistoryService> open() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return HistoryService(box);
  }

  /// Agrega una entrada y recorta el historial a [maxEntries].
  Future<void> add(HistoryEntry entry, {int maxEntries = 500}) async {
    await _box.add(entry.toJson());
    if (_box.length > maxEntries) {
      final excess = _box.length - maxEntries;
      final keys = _box.keys.take(excess).toList();
      await _box.deleteAll(keys);
    }
  }

  /// Entradas más recientes primero.
  List<HistoryEntry> getAll({int? limit}) {
    final entries = _box.values
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    entries.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    if (limit != null && entries.length > limit) {
      return entries.sublist(0, limit);
    }
    return entries;
  }

  /// Reemplaza el historial local con la copia del servidor.
  Future<void> replaceAll(List<HistoryEntry> entries) async {
    await _box.clear();
    for (final entry in entries.reversed) {
      await _box.add(entry.toJson());
    }
  }

  /// Fusiona el historial del servidor con el local (sin duplicar exactos).
  Future<void> mergeFromServer(List<HistoryEntry> entries) async {
    if (entries.isEmpty) return;
    final existing = getAll();
    final seen = existing
        .map((e) => '${e.trackId}@${e.playedAt.millisecondsSinceEpoch}')
        .toSet();
    for (final entry in entries.reversed) {
      final key = '${entry.trackId}@${entry.playedAt.millisecondsSinceEpoch}';
      if (seen.contains(key)) continue;
      await _box.add(entry.toJson());
      seen.add(key);
    }
  }

  Future<void> clear() => _box.clear();

  int get length => _box.length;

  /// Últimos tracks escuchados sin repetir (para "Escuchado recientemente").
  List<HistoryEntry> recentDistinct({int limit = 10}) {
    final result = <HistoryEntry>[];
    final seen = <String>{};
    for (final entry in getAll()) {
      if (seen.add(entry.trackId)) result.add(entry);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Cuántas veces se reprodujo cada track (simple).
  Map<String, int> playCounts() {
    final counts = <String, int>{};
    for (final entry in getAll()) {
      counts.update(entry.trackId, (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  String debugDump() => Json.strings(_box.keys.toList()).join(', ');
}
