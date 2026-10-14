import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/search_results.dart';
import '../../../services/service_providers.dart';
import '../models/search_models.dart';

/// Controlador de búsqueda con debounce de 300 ms.
class SearchController extends StateNotifier<SearchState> {
  SearchController(this._ref) : super(const SearchState());

  final Ref _ref;
  Timer? _debounce;

  /// Cancela cualquier request en vuelo y reinicia el estado.
  void clear() {
    _debounce?.cancel();
    state = const SearchState();
  }

  /// Cambia la pestaña activa y reejecuta la búsqueda si hay query.
  void setType(SearchType type) {
    if (state.type == type) return;
    state = state.copyWith(type: type, loading: state.hasQuery);
    if (state.hasQuery) _run(state.query, immediate: true);
  }

  /// Actualiza el término de búsqueda (con debounce).
  void updateQuery(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(query: query, loading: true, clearError: true);
    _debounce = Timer(AppConstants.searchDebounce, () {
      _run(query, immediate: true);
    });
  }

  /// Fuerza la búsqueda ahora (retry / submit del teclado).
  Future<void> submit() => _run(state.query, immediate: true, force: true);

  Future<void> _run(
    String query, {
    bool immediate = false,
    bool force = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const SearchState();
      return;
    }
    if (!immediate && !force) return;

    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await _ref.read(searchServiceProvider).search(
            query: trimmed,
            type: state.type,
          );
      // Ignorar respuestas obsoletas.
      if (state.query.trim() != trimmed) return;
      state =
          state.copyWith(results: results, loading: false, clearError: true);
    } catch (error) {
      if (state.query.trim() != trimmed) return;
      state = state.copyWith(loading: false, error: error);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// Estado de búsqueda.
final searchProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(ref);
});
