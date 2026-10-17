package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Album
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton

/** Álbum contra `GET /api/albums/{albumId}`. */
@Singleton
class AlbumRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getAlbum(albumId: String): Album {
        val body = apiCall { api.album(ApiEndpoints.album(albumId)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        return Album.fromJson((json["album"] as? Map<*, *>)?.stringKeyed() ?: json)
    }
}
