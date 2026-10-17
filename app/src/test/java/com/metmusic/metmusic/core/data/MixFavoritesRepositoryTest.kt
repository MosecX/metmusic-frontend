package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeMixFavoritesDao
import com.metmusic.metmusic.core.model.RadioMix
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class MixFavoritesRepositoryTest {

    private val dao = FakeMixFavoritesDao()
    private val repository = MixFavoritesRepository(dao)

    private val mix = RadioMix(
        id = "mix-1",
        title = "Radio MetMusic",
        subTitle = "Artista",
        description = "Descripción",
        imageUrl = "https://img.example/1.jpg",
    )

    @Test
    fun `toggle adds when absent and returns true`() = runTest {
        val state = repository.toggle("seed-1", mix)

        assertTrue(state)
        assertTrue(repository.isFavorite("seed-1"))
    }

    @Test
    fun `toggle removes when present and returns false`() = runTest {
        repository.toggle("seed-1", mix)

        val state = repository.toggle("seed-1", mix)

        assertFalse(state)
        assertFalse(repository.isFavorite("seed-1"))
    }

    @Test
    fun `isFavorite reflects current state`() = runTest {
        assertFalse(repository.isFavorite("seed-1"))

        repository.toggle("seed-1", mix)

        assertTrue(repository.isFavorite("seed-1"))
    }

    @Test
    fun `getAll returns saved mixes with their seed track`() = runTest {
        repository.toggle("seed-1", mix)

        val saved = repository.getAll()

        assertEquals(1, saved.size)
        assertEquals("seed-1", saved[0].trackId)
        assertEquals("mix-1", saved[0].mix.id)
        assertEquals("Radio MetMusic", saved[0].mix.title)
        assertEquals("Artista", saved[0].mix.subTitle)
        assertEquals("Descripción", saved[0].mix.description)
        assertEquals("https://img.example/1.jpg", saved[0].mix.imageUrl)
    }
}
