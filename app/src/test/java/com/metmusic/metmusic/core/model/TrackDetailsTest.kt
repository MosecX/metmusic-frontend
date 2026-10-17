package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import kotlin.time.Duration.Companion.seconds
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class TrackDetailsTest {

    @Test
    fun `parses the full payload`() {
        val details = TrackDetails.fromJson(
            JsonParse.parse(
                """
                {
                  "id": "t1",
                  "title": "Canción",
                  "artist": "Banda",
                  "artist_id": "a1",
                  "album": "Álbum",
                  "album_id": "al1",
                  "duration": 210,
                  "isrc": "ISRC123",
                  "quality": "HI_RES",
                  "version": "Remix",
                  "copyright": "(c) 2026",
                  "popularity": 0.75,
                  "bpm": "128.5",
                  "peak": 0.98,
                  "explicit": true,
                  "stream_ready": true
                }
                """.trimIndent(),
            )!!,
        )

        assertEquals("t1", details.trackId)
        assertEquals("Canción", details.title)
        assertEquals("Banda", details.artist)
        assertEquals("a1", details.artistId)
        assertEquals("Álbum", details.album)
        assertEquals("al1", details.albumId)
        assertEquals(210, details.durationSeconds)
        assertEquals(210.seconds, details.duration)
        assertEquals("ISRC123", details.isrc)
        assertEquals("HI_RES", details.quality)
        assertEquals("Remix", details.version)
        assertEquals("(c) 2026", details.copyright)
        assertEquals(0.75, details.popularity!!)
        assertEquals(128.5, details.bpm!!)
        assertEquals(0.98, details.peak!!)
        assertTrue(details.explicit)
        assertTrue(details.streamReady)
    }

    @Test
    fun `falls back on defaults`() {
        val details = TrackDetails.fromJson(emptyMap())

        assertEquals("", details.trackId)
        assertEquals("Desconocido", details.title)
        assertEquals(0, details.durationSeconds)
        assertEquals(0.seconds, details.duration)
        assertNull(details.artist)
        assertNull(details.bpm)
        assertFalse(details.explicit)
        assertFalse(details.streamReady)
    }
}
