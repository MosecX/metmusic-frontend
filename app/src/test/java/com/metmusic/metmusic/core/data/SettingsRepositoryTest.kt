package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeSettingsStorage
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.RepeatMode
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class SettingsRepositoryTest {

    private val storage = FakeSettingsStorage()
    private val repository = SettingsRepository(storage)

    @Test
    fun `defaults are exposed through the flow`() = runTest {
        val settings = repository.settings.first()

        assertEquals(AudioQualityPreference.DEFAULT, settings.audioQuality)
        assertEquals(RepeatMode.OFF, settings.repeatMode)
        assertFalse(settings.shuffle)
    }

    @Test
    fun `set audio quality persists`() = runTest {
        repository.setAudioQuality(AudioQualityPreference.MEDIUM)

        assertEquals(AudioQualityPreference.MEDIUM, repository.settings.first().audioQuality)
    }

    @Test
    fun `set repeat mode persists`() = runTest {
        repository.setRepeatMode(RepeatMode.ALL)

        assertEquals(RepeatMode.ALL, repository.settings.first().repeatMode)
    }

    @Test
    fun `set shuffle persists`() = runTest {
        repository.setShuffle(true)

        assertTrue(repository.settings.first().shuffle)
    }
}
