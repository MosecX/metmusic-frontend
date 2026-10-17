package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class HealthServiceStatusTest {

    @Test
    fun `parses a service report`() {
        val service = HealthServiceStatus.fromJson(
            JsonParse.parse(
                """
                {
                  "id": "catalog",
                  "name": "Catálogo",
                  "ok": false,
                  "latency_ms": 12.5,
                  "detail": "timeout"
                }
                """.trimIndent(),
            )!!,
        )

        assertEquals("catalog", service.id)
        assertEquals("Catálogo", service.name)
        assertEquals(false, service.ok)
        assertEquals(12.5, service.latencyMs!!)
        assertEquals("timeout", service.detail)
    }

    @Test
    fun `defaults name to id and ok to true`() {
        val service = HealthServiceStatus.fromJson(JsonParse.parse("""{"id": "stream"}""")!!)

        assertEquals("stream", service.id)
        assertEquals("stream", service.name)
        assertTrue(service.ok)
        assertNull(service.latencyMs)
        assertNull(service.detail)
    }
}
