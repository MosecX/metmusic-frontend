package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.Settings
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow

/**
 * Punto de acceso a las preferencias de reproducción.
 *
 * Envoltorio fino por ahora: el player (FASE 5) y la UI de Settings (FASE 6D)
 * lo consumen sin hablarle directo al storage.
 */
@Singleton
class SettingsRepository @Inject constructor(
    private val storage: SettingsStorage,
) {
    val settings: Flow<Settings> = storage.settings

    suspend fun setAudioQuality(quality: AudioQualityPreference) = storage.setAudioQuality(quality)

    suspend fun setRepeatMode(mode: RepeatMode) = storage.setRepeatMode(mode)

    suspend fun setShuffle(shuffle: Boolean) = storage.setShuffle(shuffle)
}
