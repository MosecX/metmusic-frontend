package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.model.TrackDetails
import com.metmusic.metmusic.core.network.ApiEndpoints
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.apiCall
import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed
import javax.inject.Inject
import javax.inject.Singleton

/** Metadatos de pista contra `GET /api/tracks/{trackId}`. */
@Singleton
class TrackRepository @Inject constructor(
    private val api: MetMusicApi,
) {
    suspend fun getTrack(trackId: String): Track = Track.fromJson(unwrap(trackId))

    /** El TrackSchema completo (ISRC, BPM, popularidad...) para el modal de metadatos. */
    suspend fun getTrackDetails(trackId: String): TrackDetails =
        TrackDetails.fromJson(unwrap(trackId))

    /** El backend puede envolver el track en `{track: {...}}`. */
    private suspend fun unwrap(trackId: String): Map<String, Any?> {
        val body = apiCall { api.track(ApiEndpoints.track(trackId)) }.string()
        val json = JsonParse.parse(body) ?: emptyMap()
        return (json["track"] as? Map<*, *>)?.stringKeyed() ?: json
    }
}
