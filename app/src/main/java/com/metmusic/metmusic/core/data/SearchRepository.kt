package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.SearchResults
import com.metmusic.metmusic.core.model.SearchType
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import javax.inject.Inject
import javax.inject.Singleton

/** Búsqueda contra GET /api/search. */
@Singleton
class SearchRepository @Inject constructor(private val api: MetMusicApi) {

    suspend fun search(
        query: String,
        type: SearchType,
        limit: Int = 30,
        offset: Int = 0,
    ): SearchResults {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return SearchResults.EMPTY

        val body = apiCall { api.search(trimmed, type.value, limit, offset) }.string()
        val json = JsonParse.parse(body) ?: emptyMap<String, Any?>()
        return SearchResults.fromJson(json, query = trimmed)
    }
}
