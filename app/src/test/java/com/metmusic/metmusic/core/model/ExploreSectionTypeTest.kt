package com.metmusic.metmusic.core.model

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class ExploreSectionTypeTest {

    @Test
    fun `parses track aliases`() {
        assertEquals(ExploreSectionType.TRACKS, ExploreSectionType.parse("tracks"))
        assertEquals(ExploreSectionType.TRACKS, ExploreSectionType.parse("songs"))
        assertEquals(ExploreSectionType.TRACKS, ExploreSectionType.parse("Charts"))
    }

    @Test
    fun `parses album aliases`() {
        assertEquals(ExploreSectionType.ALBUMS, ExploreSectionType.parse("albums"))
        assertEquals(ExploreSectionType.ALBUMS, ExploreSectionType.parse("releases"))
        assertEquals(ExploreSectionType.ALBUMS, ExploreSectionType.parse("new_releases"))
    }

    @Test
    fun `parses artists and playlists`() {
        assertEquals(ExploreSectionType.ARTISTS, ExploreSectionType.parse("artists"))
        assertEquals(ExploreSectionType.PLAYLISTS, ExploreSectionType.parse("playlists"))
    }

    @Test
    fun `falls back to unknown`() {
        assertEquals(ExploreSectionType.UNKNOWN, ExploreSectionType.parse("moods"))
        assertEquals(ExploreSectionType.UNKNOWN, ExploreSectionType.parse(""))
        assertEquals(ExploreSectionType.UNKNOWN, ExploreSectionType.parse(null))
    }
}
