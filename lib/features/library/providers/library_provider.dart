import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/track.dart';
import '../../../core/models/user_playlist.dart';
import '../../../services/service_providers.dart';
import '../models/library_models.dart';

/// Pestaña activa de la Library.
final libraryTabProvider = StateProvider<LibraryTab>((ref) => LibraryTab.playlists);

// ---------------------------------------------------------------------------
// Playlists del usuario (con caché local en Hive para modo offline)
// ---------------------------------------------------------------------------

/// Controlador de las playlists propias.
class UserPlaylistsController extends AsyncNotifier<List<UserPlaylist>> {
  Box<dynamic>? get _box {
    try {
      return Hive.box<dynamic>(AppConstants.hiveBoxPlaylists);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<UserPlaylist>> build() async {
    final cached = _readCache();
    try {
      final remote = await ref.read(userServiceProvider).getPlaylists();
      await _writeCache(remote);
      return remote;
    } catch (error) {
      // Offline: devolvemos la caché si existe.
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  List<UserPlaylist> _readCache() {
    final box = _box;
    if (box == null) return const [];
    return box.values
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => UserPlaylist.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<void> _writeCache(List<UserPlaylist> playlists) async {
    final box = _box;
    if (box == null) return;
    await box.clear();
    for (final playlist in playlists) {
      if (playlist.id.isEmpty) continue;
      await box.put(playlist.id, playlist.toJson());
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// `POST /api/user/playlists`
  Future<UserPlaylist> create(CreatePlaylistDraft draft) async {
    final created = await ref.read(userServiceProvider).createPlaylist(
          name: draft.name.trim(),
          description: draft.description,
          coverUrl: draft.coverUrl,
        );
    final current = state.valueOrNull ?? const <UserPlaylist>[];
    final updated = [...current, created];
    state = AsyncValue.data(updated);
    await _writeCache(updated);
    return created;
  }

  /// `PUT /api/user/playlists/{id}`
  Future<void> rename(String id, String name) async {
    final current = state.valueOrNull ?? const <UserPlaylist>[];
    final optimistic = [
      for (final p in current) p.id == id ? p.copyWith(name: name) : p,
    ];
    state = AsyncValue.data(optimistic);
    try {
      await ref.read(userServiceProvider).updatePlaylist(id, name: name);
      await _writeCache(optimistic);
    } catch (_) {
      // Se mantiene el cambio local.
    }
  }

  /// `DELETE /api/user/playlists/{id}`
  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? const <UserPlaylist>[];
    final optimistic = current.where((p) => p.id != id).toList();
    state = AsyncValue.data(optimistic);
    await _writeCache(optimistic);
    await ref.read(userServiceProvider).deletePlaylist(id);
  }

  /// `POST /api/user/playlists/{id}/tracks`
  Future<void> addTracks(String id, List<String> trackIds) async {
    await ref.read(userServiceProvider).addTracks(id, trackIds);
    ref.invalidate(userPlaylistDetailProvider(id));
  }

  /// `DELETE /api/user/playlists/{id}/tracks/{trackId}`
  Future<void> removeTrack(String id, String trackId) async {
    await ref.read(userServiceProvider).removeTrack(id, trackId);
    ref.invalidate(userPlaylistDetailProvider(id));
  }

  /// `PUT /api/user/playlists/{id}/reorder`
  Future<void> reorder(String id, List<String> orderedIds) async {
    await ref.read(userServiceProvider).reorder(id, orderedIds);
    ref.invalidate(userPlaylistDetailProvider(id));
  }
}

final userPlaylistsProvider =
    AsyncNotifierProvider<UserPlaylistsController, List<UserPlaylist>>(
  UserPlaylistsController.new,
);

/// Detalle de una playlist propia.
final userPlaylistDetailProvider =
    FutureProvider.family<UserPlaylist, String>((ref, id) async {
  return ref.watch(userServiceProvider).getPlaylist(id);
});

// ---------------------------------------------------------------------------
// Favoritos
// ---------------------------------------------------------------------------

/// Controlador de favoritos: local (Hive) como fuente de verdad + sync backend.
class FavoritesController extends AsyncNotifier<List<Track>> {
  @override
  Future<List<Track>> build() async {
    final local = ref.read(favoritesServiceProvider);
    final cached = local.getAll();
    try {
      final remote = await ref.read(userServiceProvider).getFavorites();
      await local.replaceAll(remote);
      return remote;
    } catch (_) {
      return cached; // offline
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  bool isFavorite(String trackId) =>
      ref.read(favoritesServiceProvider).isFavorite(trackId);

  /// Alterna el favorito y devuelve el nuevo estado.
  Future<bool> toggle(Track track) async {
    final local = ref.read(favoritesServiceProvider);
    final nowFavorite = await local.toggle(track);

    final current = state.valueOrNull ?? local.getAll();
    final updated = nowFavorite
        ? [track, ...current.where((t) => t.trackId != track.trackId)]
        : current.where((t) => t.trackId != track.trackId).toList();
    state = AsyncValue.data(updated);

    try {
      final service = ref.read(userServiceProvider);
      if (nowFavorite) {
        await service.addFavorite(track.trackId);
      } else {
        await service.removeFavorite(track.trackId);
      }
    } catch (_) {
      // Offline: el estado local se sincronizará luego.
    }
    return nowFavorite;
  }

  Future<void> remove(String trackId) async {
    final local = ref.read(favoritesServiceProvider);
    Track? track;
    for (final candidate in local.getAll()) {
      if (candidate.trackId == trackId) {
        track = candidate;
        break;
      }
    }
    await local.remove(trackId);
    final current = state.valueOrNull ?? const <Track>[];
    state = AsyncValue.data(
      current.where((t) => t.trackId != trackId).toList(),
    );
    try {
      await ref.read(userServiceProvider).removeFavorite(trackId);
    } catch (_) {
      if (track != null) await local.add(track);
    }
  }
}

final favoritesListProvider =
    AsyncNotifierProvider<FavoritesController, List<Track>>(
  FavoritesController.new,
);

/// Ids de favoritos (para badges instantáneos en la UI).
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final list = ref.watch(favoritesListProvider).valueOrNull;
  if (list != null) return list.map((t) => t.trackId).toSet();
  return ref.watch(favoritesServiceProvider).ids;
});

/// True si el track está en favoritos.
final isFavoriteProvider = Provider.family<bool, String>((ref, trackId) {
  return ref.watch(favoriteIdsProvider).contains(trackId);
});

// ---------------------------------------------------------------------------
// Historial
// ---------------------------------------------------------------------------

/// Controlador del historial de reproducción.
class HistoryController extends AsyncNotifier<List<HistoryEntry>> {
  @override
  Future<List<HistoryEntry>> build() async {
    final local = ref.read(historyServiceProvider);
    final cached = local.getAll();
    try {
      final remote = await ref.read(userServiceProvider).getHistory(limit: 100);
      await local.mergeFromServer(remote);
      final merged = local.getAll();
      return merged.isEmpty ? cached : merged;
    } catch (_) {
      return cached; // offline
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  /// `DELETE /api/user/history` + limpieza local.
  Future<void> clear() async {
    await ref.read(historyServiceProvider).clear();
    state = const AsyncValue.data([]);
    try {
      await ref.read(userServiceProvider).clearHistory();
    } catch (_) {
      // Local ya limpio; el servidor se limpia al reconectar.
    }
  }

  /// Registra una reproducción local (usado por el player).
  Future<void> record(HistoryEntry entry) async {
    await ref.read(historyServiceProvider).add(entry);
    final current = state.valueOrNull ?? const <HistoryEntry>[];
    state = AsyncValue.data([entry, ...current]);
  }
}

final historyListProvider =
    AsyncNotifierProvider<HistoryController, List<HistoryEntry>>(
  HistoryController.new,
);
