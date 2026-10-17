package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class ExploreSectionTest {

    @Test
    fun `parses an explicit section`() {
        val section = ExploreSection.fromJson(
            "new_releases",
            JsonParse.parse(
                """
                {
                  "title": "Nuevos lanzamientos",
                  "type": "albums",
                  "items": [{"album_id": "al1", "title": "Uno"}]
                }
                """.trimIndent(),
            ),
        )

        assertEquals("new_releases", section.id)
        assertEquals("Nuevos lanzamientos", section.title)
        assertEquals(ExploreSectionType.ALBUMS, section.type)
        assertEquals(1, section.albums.size)
        assertEquals("al1", section.albums[0].albumId)
        assertTrue(section.tracks.isEmpty())
    }

    @Test
    fun `accepts a bare list and infers from the key`() {
        val section = ExploreSection.fromJson(
            "charts",
            listOf(mapOf("track_id" to "t1", "title" to "Hit")),
        )

        assertEquals(ExploreSectionType.TRACKS, section.type)
        assertEquals("Charts", section.title)
        assertEquals(1, section.tracks.size)
    }

    @Test
    fun `detects the type from the first item`() {
        val section = ExploreSection.fromJson(
            "mystery",
            listOf(mapOf("album_id" to "al9", "title" to "X")),
        )

        assertEquals(ExploreSectionType.ALBUMS, section.type)
        assertEquals("al9", section.albums[0].albumId)
    }

    @Test
    fun `explicit type wins over the key`() {
        val section = ExploreSection.fromJson(
            "charts",
            JsonParse.parse("""{"type": "albums", "items": [{"album_id": "al1", "title": "Uno"}]}"""),
        )

        assertEquals(ExploreSectionType.ALBUMS, section.type)
        assertEquals(1, section.albums.size)
    }

    @Test
    fun `humanizes the key and marks empty sections`() {
        val section = ExploreSection.fromJson("moody_sessions", emptyList<Any?>())

        assertEquals("Moody sessions", section.title)
        assertEquals(ExploreSectionType.UNKNOWN, section.type)
        assertTrue(section.isEmpty)
    }
}
