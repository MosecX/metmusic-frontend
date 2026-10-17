package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class UserPlaylistTest {

    @Test
    fun `parses a full payload`() {
        val json = JsonParse.parse(
            """
            {
              "id": "pl-1",
              "name": "Mis favoritas",
              "description": "Selección a mano",
              "cover_url": "https://cdn.example/cover.jpg",
              "track_count": 7,
              "created_at": "2026-01-02T03:04:05Z",
              "updated_at": "2026-01-03T03:04:05Z",
              "tracks": [
                {"track_id": "t1", "title": "Una", "duration_seconds": 180},
                {"track_id": "t2", "title": "Otra"}
              ]
            }
            """.trimIndent(),
        )!!

        val playlist = UserPlaylist.fromJson(json)

        assertEquals("pl-1", playlist.playlistId)
        assertEquals("Mis favoritas", playlist.name)
        assertEquals("Selección a mano", playlist.description)
        assertEquals("https://cdn.example/cover.jpg", playlist.coverUrl)
        assertEquals(7, playlist.trackCount)
        assertEquals(2, playlist.tracks.size)
        assertEquals("t1", playlist.tracks[0].trackId)
        assertEquals("2026-01-02T03:04:05Z", playlist.createdAt)
        assertEquals("2026-01-03T03:04:05Z", playlist.updatedAt)
    }

    @Test
    fun `falls back on missing fields`() {
        val playlist = UserPlaylist.fromJson(JsonParse.parse("""{"uuid": "u-9"}""")!!)

        assertEquals("u-9", playlist.playlistId)
        assertEquals("Sin título", playlist.name)
        assertEquals(0, playlist.trackCount)
        assertEquals("", playlist.thumbnailUrl)
        assertTrue(playlist.syntheticThumbnails.isEmpty())
    }

    @Test
    fun `computes trackCount from tracks when absent`() {
        val playlist = UserPlaylist.fromJson(
            JsonParse.parse(
                """{"id": "p", "tracks": [{"track_id": "t1"}, {"track_id": "t2"}]}""",
            )!!,
        )

        assertEquals(2, playlist.trackCount)
    }

    @Test
    fun `derives synthetic thumbnails from the cover`() {
        val playlist = UserPlaylist.fromJson(
            JsonParse.parse("""{"id": "p", "cover": "https://cdn.example/c.jpg"}""")!!,
        )

        assertEquals(1, playlist.syntheticThumbnails.size)
        assertEquals("https://cdn.example/c.jpg", playlist.syntheticThumbnails[0].url)
        assertEquals("https://cdn.example/c.jpg", playlist.thumbnailUrl)
    }
}
