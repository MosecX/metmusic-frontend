package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class CanvasMediaTest {

    @Test
    fun `parses an HLS canvas`() {
        val canvas = CanvasMedia.fromJson(
            JsonParse.parse(
                """{"url": "https://cdn.example/video.m3u8", "kind": "HLS", "provider": "Tidal"}""",
            )!!,
        )

        assertTrue(canvas.isHls)
        assertFalse(canvas.isMp4)
        assertEquals("https://cdn.example/video.m3u8", canvas.displayUrl)
    }

    @Test
    fun `prefers the tall URL for Apple canvases`() {
        val apple = CanvasMedia.fromJson(
            JsonParse.parse(
                """
                {
                  "url": "https://cdn.example/h.mp4",
                  "url_tall": "https://cdn.example/v.mp4",
                  "provider": "Apple Music"
                }
                """.trimIndent(),
            )!!,
        )
        assertEquals("https://cdn.example/v.mp4", apple.displayUrl)

        val other = CanvasMedia.fromJson(
            JsonParse.parse(
                """
                {
                  "url": "https://cdn.example/h.mp4",
                  "url_tall": "https://cdn.example/v.mp4",
                  "provider": "Spotify"
                }
                """.trimIndent(),
            )!!,
        )
        assertEquals("https://cdn.example/h.mp4", other.displayUrl)
    }

    @Test
    fun `falls back to the normal URL for Apple without a tall URL`() {
        val canvas = CanvasMedia.fromJson(
            JsonParse.parse("""{"url": "https://cdn.example/h.mp4", "provider": "apple"}""")!!,
        )

        assertEquals("https://cdn.example/h.mp4", canvas.displayUrl)
    }

    @Test
    fun `defaults to mp4`() {
        val canvas = CanvasMedia.fromJson(JsonParse.parse("""{}""")!!)

        assertEquals("", canvas.url)
        assertNull(canvas.provider)
        assertEquals("mp4", canvas.kind)
        assertTrue(canvas.isMp4)
        assertEquals("", canvas.displayUrl)
    }
}
