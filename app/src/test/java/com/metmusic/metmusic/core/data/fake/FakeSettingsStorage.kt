package com.metmusic.metmusic.core.data.fake

import com.metmusic.metmusic.core.data.SettingsStorage
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.Settings
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/** SettingsStorage en memoria para tests JVM. */
class FakeSettingsStorage : SettingsStorage {

    private val state = MutableStateFlow(Settings())

    override val settings: Flow<Settings> = state

    override suspend fun setAudioQuality(quality: AudioQualityPreference) {
        state.value = state.value.copy(audioQuality = quality)
    }

    override suspend fun setRepeatMode(mode: RepeatMode) {
        state.value = state.value.copy(repeatMode = mode)
    }

    override suspend fun setShuffle(shuffle: Boolean) {
        state.value = state.value.copy(shuffle = shuffle)
    }
}
