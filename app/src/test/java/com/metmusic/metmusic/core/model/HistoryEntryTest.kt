package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import java.time.Instant
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class HistoryEntryTest {

    @Test
    fun `parses ISO dates, epoch seconds and epoch millis`() {
        val iso = HistoryEntry.fromJson(
            JsonParse.parse("""{"track_id": "t1", "played_at": "2026-01-02T03:04:05Z"}""")!!,
        )
        assertEquals(Instant.parse("2026-01-02T03:04:05Z").toEpochMilli(), iso.playedAt)

        val seconds = HistoryEntry.fromJson(
            JsonParse.parse("""{"track_id": "t1", "played_at": 1700000000}""")!!,
        )
        assertEquals(1_700_000_000_000L, seconds.playedAt)

        val millis = HistoryEntry.fromJson(
            JsonParse.parse("""{"track_id": "t1", "timestamp": 1700000000000}""")!!,
        )
        assertEquals(1_700_000_000_000L, millis.playedAt)
    }

    @Test
    fun `uses now when the date is missing or invalid`() {
        val before = System.currentTimeMillis()
        val entry = HistoryEntry.fromJson(
            JsonParse.parse("""{"track_id": "t1", "played_at": "ayer"}""")!!,
        )
        val after = System.currentTimeMillis()

        assertTrue(entry.playedAt in before..after)
    }

    @Test
    fun `parses defaults and embedded track metadata`() {
        val entry = HistoryEntry.fromJson(
            JsonParse.parse(
                """
                {
                  "track_id": "t9",
                  "created_at": "1700000000",
                  "played_ms": 42000,
                  "completed": true,
                  "track": {"track_id": "t9", "title": "Himno", "artist": "La Banda"}
                }
                """.trimIndent(),
            )!!,
        )

        assertEquals("t9", entry.trackId)
        assertEquals(1_700_000_000_000L, entry.playedAt)
        assertEquals(42000, entry.playedMs)
        assertTrue(entry.completed)
        assertEquals("Himno", entry.title)
        assertEquals("La Banda", entry.artist)
    }

    @Test
    fun `builds the track from top level fields when embedded track is missing`() {
        val entry = HistoryEntry.fromJson(
            JsonParse.parse("""{"track_id": "t3", "title": "Suelta", "artist": "Banda"}""")!!,
        )

        assertEquals("Suelta", entry.title)
        assertEquals("Banda", entry.artist)
        assertEquals(0, entry.playedMs)
        assertFalse(entry.completed)
    }

    @Test
    fun `listFrom skips non map items`() {
        val entries = HistoryEntry.listFrom(listOf(mapOf("track_id" to "t1"), "nope", 7))

        assertEquals(1, entries.size)
        assertEquals("t1", entries[0].trackId)
        assertEquals(0, entries[0].playedMs)
    }
}
