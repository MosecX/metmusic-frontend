package com.metmusic.metmusic.core.model

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class AudioQualityPreferenceTest {

    @Test
    fun `exposes the backend values in order`() {
        assertEquals(
            listOf("best", "medium", "low"),
            AudioQualityPreference.entries.map { it.value },
        )
        assertEquals(AudioQualityPreference.BEST, AudioQualityPreference.DEFAULT)
    }

    @Test
    fun `fromValue maps stored strings and falls back to best`() {
        assertEquals(AudioQualityPreference.BEST, AudioQualityPreference.fromValue("best"))
        assertEquals(AudioQualityPreference.MEDIUM, AudioQualityPreference.fromValue("medium"))
        assertEquals(AudioQualityPreference.LOW, AudioQualityPreference.fromValue("low"))
        assertEquals(AudioQualityPreference.BEST, AudioQualityPreference.fromValue("unknown"))
        assertEquals(AudioQualityPreference.BEST, AudioQualityPreference.fromValue(null))
    }
}
