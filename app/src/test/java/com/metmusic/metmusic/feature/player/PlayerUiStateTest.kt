package com.metmusic.metmusic.feature.player

import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.StreamInfo
import com.metmusic.metmusic.core.model.Thumbnail
import com.metmusic.metmusic.core.model.Track
import java.time.Duration
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class PlayerUiStateTest {

    private fun track(
        id: String = "t1",
        thumbnails: List<Thumbnail> = emptyList(),
    ): Track = Track(
        trackId = id,
        title = "Song",
        artist = "Artist",
        album = "Album",
        thumbnails = thumbnails,
    )

    @Test
    fun `default state is empty`() {
        val state = PlayerUiState()
        assertNull(state.mediaId)
        assertNull(state.track)
        assertFalse(state.isPlaying)
        assertFalse(state.isBuffering)
        assertEquals(PlayerUiState.ProcessingState.IDLE, state.processingState)
        assertEquals(Duration.ZERO, state.position)
        assertEquals(Duration.ZERO, state.duration)
        assertEquals(Duration.ZERO, state.buffered)
        assertTrue(state.queue.isEmpty())
        assertEquals(-1, state.currentIndex)
        assertFalse(state.shuffleEnabled)
        assertEquals(RepeatMode.OFF, state.repeatMode)
        assertNull(state.streamInfo)
        assertNull(state.error)
        assertEquals(PlayerUiState.EMPTY, state)
    }

    @Test
    fun `hasTrack reflects presence of track`() {
        assertFalse(PlayerUiState().hasTrack)
        assertTrue(PlayerUiState(track = track()).hasTrack)
    }

    @Test
    fun `title and artist fall back correctly`() {
        val empty = PlayerUiState()
        assertEquals("", empty.title)
        assertEquals("", empty.artist)
        assertEquals("", empty.album)

        val versioned = PlayerUiState(
            track = Track(trackId = "t1", title = "Song", version = "Live"),
        )
        assertEquals("Song (Live)", versioned.title)
        assertEquals("", versioned.artist)
        assertEquals("", versioned.album)
    }

    @Test
    fun `progress is 0 when duration is zero`() {
        val state = PlayerUiState(
            track = track(),
            position = Duration.ofSeconds(30),
            duration = Duration.ZERO,
        )
        assertEquals(0f, state.progress)
    }

    @Test
    fun `progress clamps to 1 when position exceeds duration`() {
        val past = PlayerUiState(
            position = Duration.ofSeconds(150),
            duration = Duration.ofSeconds(100),
        )
        assertEquals(1f, past.progress)

        val half = PlayerUiState(
            position = Duration.ofSeconds(50),
            duration = Duration.ofSeconds(100),
        )
        assertEquals(0.5f, half.progress)
    }

    @Test
    fun `hasNext and hasPrevious reflect index bounds`() {
        val queue = listOf(track("a"), track("b"), track("c"))

        val first = PlayerUiState(queue = queue, currentIndex = 0)
        assertTrue(first.hasNext)
        assertFalse(first.hasPrevious)

        val middle = PlayerUiState(queue = queue, currentIndex = 1)
        assertTrue(middle.hasNext)
        assertTrue(middle.hasPrevious)

        val last = PlayerUiState(queue = queue, currentIndex = 2)
        assertFalse(last.hasNext)
        assertTrue(last.hasPrevious)

        val none = PlayerUiState()
        assertFalse(none.hasNext)
        assertFalse(none.hasPrevious)
    }

    @Test
    fun `artworkUrl prefers streamInfo thumbnail over track thumbnail`() {
        val withArt = track(
            thumbnails = listOf(
                Thumbnail(url = "https://img.example/track.jpg", width = 640, height = 640),
            ),
        )
        assertTrue(withArt.thumbnailUrl.isNotEmpty())
        assertEquals(withArt.thumbnailUrl, PlayerUiState(track = withArt).artworkUrl)

        val withStream = PlayerUiState(
            track = withArt,
            streamInfo = StreamInfo(
                url = "https://stream.example/audio.flac",
                trackId = "t1",
                thumbnail = "https://img.example/stream.jpg",
            ),
        )
        assertEquals("https://img.example/stream.jpg", withStream.artworkUrl)
    }
}
