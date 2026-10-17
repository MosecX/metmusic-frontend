package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class ExploreHomeTest {

    @Test
    fun `parses an explicit sections array`() {
        val home = ExploreHome.fromJson(
            JsonParse.parse(
                """
                {
                  "sections": [
                    {"title": "Nuevos", "type": "albums", "items": [{"album_id": "al1", "title": "Uno"}]},
                    {"title": "Top", "type": "tracks", "items": [{"track_id": "t1", "title": "Dos"}]}
                  ]
                }
                """.trimIndent(),
            ),
        )

        assertEquals(2, home.sections.size)
        assertEquals(ExploreSectionType.ALBUMS, home.sections[0].type)
        assertEquals(ExploreSectionType.TRACKS, home.sections[1].type)
        assertFalse(home.isEmpty)
    }

    @Test
    fun `parses a map of lists and skips metadata keys`() {
        val home = ExploreHome.fromJson(
            JsonParse.parse(
                """
                {
                  "new_releases": [{"album_id": "al1", "title": "Uno"}],
                  "top_tracks": [{"track_id": "t1", "title": "Dos"}],
                  "total": 2
                }
                """.trimIndent(),
            ),
        )

        assertEquals(2, home.sections.size)
        assertEquals(setOf("new_releases", "top_tracks"), home.sections.map { it.id }.toSet())
        assertEquals(
            ExploreSectionType.ALBUMS,
            home.sections.first { it.id == "new_releases" }.type,
        )
        assertEquals(
            ExploreSectionType.TRACKS,
            home.sections.first { it.id == "top_tracks" }.type,
        )
    }

    @Test
    fun `accepts bare arrays with per section ids`() {
        val home = ExploreHome.fromJson(
            listOf(
                mapOf(
                    "id" to "featured",
                    "type" to "tracks",
                    "items" to listOf(mapOf("track_id" to "t1", "title" to "A")),
                ),
                listOf(mapOf("artist_id" to "a1", "name" to "Banda")),
            ),
        )

        assertEquals(listOf("featured", "section_1"), home.sections.map { it.id })
        assertEquals(ExploreSectionType.TRACKS, home.sections[0].type)
        assertEquals(ExploreSectionType.ARTISTS, home.sections[1].type)
    }

    @Test
    fun `falls back to the map when explicit sections are empty`() {
        val home = ExploreHome.fromJson(
            JsonParse.parse("""{"sections": [], "top_tracks": [{"track_id": "t1"}]}"""),
        )

        assertEquals(1, home.sections.size)
        assertEquals("top_tracks", home.sections[0].id)
    }

    @Test
    fun `returns an empty home for unknown payloads`() {
        assertTrue(ExploreHome.fromJson(null).isEmpty)
        assertTrue(ExploreHome.fromJson("nope").isEmpty)
        assertTrue(ExploreHome.fromJson(emptyMap<String, Any?>()).isEmpty)
    }
}
