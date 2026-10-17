package com.metmusic.metmusic.core.data.local.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.metmusic.metmusic.core.data.SettingsStorage
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.RepeatMode
import com.metmusic.metmusic.core.model.Settings
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private const val DATASTORE_NAME = "metmusic_settings"

private val Context.metMusicDataStore: DataStore<Preferences> by preferencesDataStore(name = DATASTORE_NAME)

/**
 * Implementación real con DataStore Preferences.
 *
 * Es la única clase de este archivo con `Context`; el resto del código solo
 * ve la interfaz [SettingsStorage].
 */
@Singleton
class DataStoreSettingsStorage @Inject constructor(
    @ApplicationContext private val context: Context,
) : SettingsStorage {

    private object Keys {
        val audioQuality = stringPreferencesKey("audio_quality")
        val repeatMode = stringPreferencesKey("repeat_mode")
        val shuffle = booleanPreferencesKey("shuffle")
    }

    override val settings: Flow<Settings> = context.metMusicDataStore.data.map { prefs ->
        Settings(
            audioQuality = AudioQualityPreference.fromValue(prefs[Keys.audioQuality]),
            repeatMode = prefs[Keys.repeatMode]
                ?.let { raw -> RepeatMode.entries.firstOrNull { it.value == raw } }
                ?: RepeatMode.OFF,
            shuffle = prefs[Keys.shuffle] ?: false,
        )
    }

    override suspend fun setAudioQuality(quality: AudioQualityPreference) {
        context.metMusicDataStore.edit { it[Keys.audioQuality] = quality.value }
    }

    override suspend fun setRepeatMode(mode: RepeatMode) {
        context.metMusicDataStore.edit { it[Keys.repeatMode] = mode.value }
    }

    override suspend fun setShuffle(shuffle: Boolean) {
        context.metMusicDataStore.edit { it[Keys.shuffle] = shuffle }
    }
}
