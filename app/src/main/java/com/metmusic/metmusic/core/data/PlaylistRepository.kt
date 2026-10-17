package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Playlist
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton

/** Playlist editorial contra `GET /api/playlists/{playlistUuid}`. */
@Singleton
class PlaylistRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getPlaylist(uuid: String): Playlist {
        val body = apiCall { api.playlist(ApiEndpoints.playlist(uuid)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        return Playlist.fromJson((json["playlist"] as? Map<*, *>)?.stringKeyed() ?: json)
    }
}
