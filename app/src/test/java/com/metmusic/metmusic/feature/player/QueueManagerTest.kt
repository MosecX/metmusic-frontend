package com.metmusic.metmusic.feature.player

import com.metmusic.metmusic.core.model.Track
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class QueueManagerTest {

    private val queueManager = QueueManager()

    private fun track(id: String): Track = Track(trackId = id, title = "Track $id")

    private fun ids(): List<String> = queueManager.queue.value.map { it.trackId }

    @Test
    fun `set queue sets current index clamped`() {
        val tracks = listOf(track("a"), track("b"), track("c"))
        queueManager.setQueue(tracks, 10)
        assertEquals(2, queueManager.currentIndex.value)
        queueManager.setQueue(tracks, -5)
        assertEquals(0, queueManager.currentIndex.value)
        assertEquals(tracks, queueManager.queue.value)
    }

    @Test
    fun `add track appends at the end by default`() {
        queueManager.setQueue(listOf(track("a"), track("b")), 1)
        queueManager.addTrack(track("c"))
        assertEquals(listOf("a", "b", "c"), ids())
        assertEquals(1, queueManager.currentIndex.value)
    }

    @Test
    fun `add track with next=true inserts after current`() {
        queueManager.setQueue(listOf(track("a"), track("b")), 0)
        queueManager.addTrack(track("x"), next = true)
        assertEquals(listOf("a", "x", "b"), ids())
        assertEquals(0, queueManager.currentIndex.value)
        assertEquals("a", queueManager.current()?.trackId)
    }

    @Test
    fun `removeAt current picks a neighbor`() {
        queueManager.setQueue(listOf(track("a"), track("b"), track("c")), 1)
        assertTrue(queueManager.removeAt(1))
        assertEquals(listOf("a", "c"), ids())
        assertEquals(1, queueManager.currentIndex.value)
        assertEquals("c", queueManager.current()?.trackId)
    }

    @Test
    fun `removeAt before current decrements index`() {
        queueManager.setQueue(listOf(track("a"), track("b"), track("c")), 2)
        assertFalse(queueManager.removeAt(0))
        assertEquals(listOf("b", "c"), ids())
        assertEquals(1, queueManager.currentIndex.value)
        assertEquals("c", queueManager.current()?.trackId)
    }

    @Test
    fun `move reorders and tracks current`() {
        queueManager.setQueue(listOf(track("a"), track("b"), track("c"), track("d")), 2)
        queueManager.move(0, 3)
        assertEquals(listOf("b", "c", "d", "a"), ids())
        assertEquals(1, queueManager.currentIndex.value)
        assertEquals("c", queueManager.current()?.trackId)
        queueManager.move(1, 0)
        assertEquals(listOf("c", "b", "d", "a"), ids())
        assertEquals(0, queueManager.currentIndex.value)
        assertEquals("c", queueManager.current()?.trackId)
        queueManager.move(2, 2)
        assertEquals(listOf("c", "b", "d", "a"), ids())
        assertEquals(0, queueManager.currentIndex.value)
    }

    @Test
    fun `clear empties queue`() {
        queueManager.setQueue(listOf(track("a")), 0)
        queueManager.clear()
        assertTrue(queueManager.queue.value.isEmpty())
        assertEquals(-1, queueManager.currentIndex.value)
        assertNull(queueManager.current())
    }
}
