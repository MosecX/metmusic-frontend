package com.metmusic.metmusic.feature.search

import com.metmusic.metmusic.core.model.SearchResults
import com.metmusic.metmusic.core.model.SearchType

/** Estado de la pantalla de búsqueda. */
data class SearchState(
    val query: String = "",
    val type: SearchType = SearchType.ALL,
    val isLoading: Boolean = false,
    val results: SearchResults = SearchResults.EMPTY,
    val error: String? = null,
) {
    /** Hay texto efectivo en el campo. */
    val hasQuery: Boolean get() = query.trim().isNotEmpty()

    /** Campo vacío y sin request en vuelo: estado inicial. */
    val showEmptyPrompt: Boolean get() = !hasQuery && !isLoading

    /** Búsqueda hecha, sin error y sin resultados. */
    val showNoResults: Boolean
        get() = hasQuery && !isLoading && error == null && results.isEmpty
}
