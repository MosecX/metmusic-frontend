package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.Settings
import kotlinx.coroutines.flow.Flow

/** Persistencia de preferencias de reproducción (DataStore en producción). */
interface SettingsStorage {

    val settings: Flow<Settings>

    suspend fun setAudioQuality(quality: AudioQualityPreference)

    suspend fun setRepeatMode(mode: RepeatMode)

    suspend fun setShuffle(shuffle: Boolean)
}
