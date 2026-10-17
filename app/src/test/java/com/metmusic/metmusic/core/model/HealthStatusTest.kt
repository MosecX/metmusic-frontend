package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class HealthStatusTest {

    @Test
    fun `parses the full payload`() {
        val status = HealthStatus.fromJson(
            JsonParse.parse(
                """
                {
                  "ok": true,
                  "status": "ok",
                  "version": "1.4.2",
                  "uptime_seconds": 1234.5,
                  "providers": {"tidal": "ok", "spotify": "degraded"},
                  "services": [{"id": "catalog", "name": "Catálogo", "ok": true}]
                }
                """.trimIndent(),
            )!!,
        )

        assertTrue(status.ok)
        assertEquals("ok", status.status)
        assertEquals("1.4.2", status.version)
        assertEquals(1234.5, status.uptimeSeconds!!)
        assertEquals(2, status.providers!!.size)
        assertEquals("degraded", status.providers!!["spotify"])
        assertEquals(1, status.services.size)
        assertTrue(status.services[0].ok)
        assertNotNull(status.raw)
    }

    @Test
    fun `derives ok from the status and healthy flags`() {
        val fromStatus = HealthStatus.fromJson(JsonParse.parse("""{"status": "ok"}""")!!)
        assertTrue(fromStatus.ok)

        // El elvis termina en `status == "ok"`, así que el fallback `true`
        // de boolOr queda inalcanzable: sin payload, ok es false (igual que
        // el cliente Flutter).
        val empty = HealthStatus.fromJson(emptyMap())
        assertFalse(empty.ok)
        assertEquals(null, empty.status)

        val unhealthy = HealthStatus.fromJson(JsonParse.parse("""{"healthy": false}""")!!)
        assertFalse(unhealthy.ok)
    }
}
