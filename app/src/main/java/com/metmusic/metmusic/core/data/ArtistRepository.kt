package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Artist
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton

/** Artista contra `GET /api/artists/{artistId}`. */
@Singleton
class ArtistRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getArtist(artistId: String): Artist {
        val body = apiCall { api.artist(ApiEndpoints.artist(artistId)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        return Artist.fromJson((json["artist"] as? Map<*, *>)?.stringKeyed() ?: json)
    }
}
