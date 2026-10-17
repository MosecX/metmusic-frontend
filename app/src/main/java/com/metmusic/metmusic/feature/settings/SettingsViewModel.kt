package com.metmusic.metmusic.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.SettingsRepository
import com.metmusic.metmusic.core.model.Settings
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn

/**
 * Preferencias de reproducción para la pantalla de Ajustes. Solo lectura en
 * 6A-2; la edición (calidad, repeat, shuffle, health, caché) llega en 6D.
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    settingsRepository: SettingsRepository,
) : ViewModel() {

    val settings: StateFlow<Settings> = settingsRepository.settings
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = Settings(),
        )
}
