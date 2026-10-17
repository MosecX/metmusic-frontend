package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class RadioMixTest {

    @Test
    fun `parses the mix payload`() {
        val mix = RadioMix.fromJson(
            JsonParse.parse(
                """
                {
                  "id": "mix-1",
                  "title": "Radio Himno",
                  "sub_title": "La Banda",
                  "description": "Parecidos a Himno",
                  "image_url": "https://cdn.example/radio.jpg"
                }
                """.trimIndent(),
            )!!,
        )

        assertEquals("mix-1", mix.id)
        assertEquals("Radio Himno", mix.title)
        assertEquals("La Banda", mix.subTitle)
        assertEquals("Parecidos a Himno", mix.description)
        assertEquals("https://cdn.example/radio.jpg", mix.imageUrl)
    }

    @Test
    fun `falls back to empty strings`() {
        val mix = RadioMix.fromJson(emptyMap())

        assertEquals("", mix.id)
        assertEquals("", mix.title)
        assertNull(mix.subTitle)
        assertNull(mix.description)
        assertNull(mix.imageUrl)
    }
}
