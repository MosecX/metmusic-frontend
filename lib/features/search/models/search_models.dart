import '../../../core/models/search_results.dart';

/// Estado de la pantalla de búsqueda.
class SearchState {
  const SearchState({
    this.query = '',
    this.type = SearchType.all,
    this.results = SearchResults.empty,
    this.loading = false,
    this.error,
  });

  final String query;
  final SearchType type;
  final SearchResults results;
  final bool loading;
  final Object? error;

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => !results.isEmpty;
  bool get showEmptyPrompt => !hasQuery && !loading;
  bool get showNoResults =>
      hasQuery && !loading && error == null && results.isEmpty;

  SearchState copyWith({
    String? query,
    SearchType? type,
    SearchResults? results,
    bool? loading,
    Object? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      type: type ?? this.type,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Resultado parcial mostrado por pestaña.
class SearchTabResults {
  const SearchTabResults({required this.items, required this.total});

  final List<Object> items;
  final int total;
}
