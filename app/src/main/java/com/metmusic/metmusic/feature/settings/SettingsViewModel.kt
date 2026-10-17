package com.metmusic.metmusic.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.metmusic.metmusic.core.data.HealthRepository
import com.metmusic.metmusic.core.data.SettingsRepository
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.network.ApiException
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Ajustes reales (6D): observa las preferencias persistidas, edita la
 * calidad de audio, consulta el estado de los servicios y limpia la caché
 * del servidor.
 */
@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val healthRepository: HealthRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(SettingsUiState())
    val state: StateFlow<SettingsUiState> = _state.asStateFlow()

    init {
        observeSettings()
        refreshHealth()
    }

    private fun observeSettings() {
        viewModelScope.launch {
            settingsRepository.settings.collectLatest { settings ->
                _state.update { it.copy(settings = settings) }
            }
        }
    }

    /** Persiste la calidad elegida y confirma con snackbar. */
    fun setQuality(quality: AudioQualityPreference) {
        viewModelScope.launch {
            try {
                settingsRepository.setAudioQuality(quality)
                _state.update { it.copy(actionMessage = "Calidad actualizada") }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update { it.copy(actionMessage = "No se pudo guardar la calidad") }
            }
        }
    }

    /** Consulta `GET /api/health`; el error se muestra inline en la sección. */
    fun refreshHealth() {
        viewModelScope.launch {
            _state.update { it.copy(isLoadingHealth = true, healthError = null) }
            try {
                val status = healthRepository.check()
                _state.update {
                    it.copy(
                        isLoadingHealth = false,
                        healthStatus = status,
                        healthServices = status.services,
                        healthError = null,
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isLoadingHealth = false, healthError = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isLoadingHealth = false, healthError = "No se pudo consultar el estado")
                }
            }
        }
    }

    /** `DELETE /api/cache`: silencioso hasta confirmar (o fallar). */
    fun clearServerCache() {
        if (_state.value.isClearingCache) return
        viewModelScope.launch {
            _state.update { it.copy(isClearingCache = true) }
            try {
                healthRepository.clearServerCache()
                _state.update {
                    it.copy(isClearingCache = false, actionMessage = "Caché del servidor limpiada")
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: ApiException) {
                _state.update {
                    it.copy(isClearingCache = false, actionMessage = e.userMessage)
                }
            } catch (e: Exception) {
                _state.update {
                    it.copy(isClearingCache = false, actionMessage = "No se pudo limpiar la caché")
                }
            }
        }
    }

    /** Dismiss del snackbar de acciones. */
    fun dismissActionMessage() {
        _state.update { it.copy(actionMessage = null) }
    }
}
