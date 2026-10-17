package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class RadioStationTest {

    @Test
    fun `parses mix and items`() {
        val station = RadioStation.fromJson(
            JsonParse.parse(
                """
                {
                  "track_id": "seed",
                  "mix": {"id": "m1", "title": "Estación para vos"},
                  "items": [
                    {"track_id": "t1", "title": "A"},
                    {"track_id": "t2", "title": "B"}
                  ]
                }
                """.trimIndent(),
            )!!,
        )

        assertEquals("seed", station.trackId)
        assertEquals("m1", station.mix.id)
        assertEquals("Estación para vos", station.mix.title)
        assertEquals(2, station.items.size)
        assertEquals("t1", station.items[0].trackId)
    }

    @Test
    fun `tolerates a missing mix`() {
        val station = RadioStation.fromJson(JsonParse.parse("""{"track_id": "seed"}""")!!)

        assertEquals("seed", station.trackId)
        assertEquals("", station.mix.id)
        assertEquals("", station.mix.title)
        assertTrue(station.items.isEmpty())
    }
}
