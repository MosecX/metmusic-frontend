package com.metmusic.metmusic.feature.settings

import androidx.compose.runtime.Immutable
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.HealthServiceStatus
import com.metmusic.metmusic.core.model.HealthStatus
import com.metmusic.metmusic.core.model.Settings

/**
 * Snapshot de Ajustes: preferencias persistidas, estado del backend y
 * banderas de UI. [actionMessage] alimenta el snackbar de acciones puntuales
 * (calidad, caché); el error de health tiene su propio feedback inline.
 */
@Immutable
data class SettingsUiState(
    val settings: Settings = Settings(),
    val healthStatus: HealthStatus? = null,
    val healthServices: List<HealthServiceStatus> = emptyList(),
    val isLoadingHealth: Boolean = false,
    val healthError: String? = null,
    val isClearingCache: Boolean = false,
    val actionMessage: String? = null,
) {
    val audioQuality: AudioQualityPreference get() = settings.audioQuality

    companion object {
        /** Estado de muestra sin estado del backend (previews). */
        fun preview(): SettingsUiState = SettingsUiState(
            settings = Settings(),
            healthStatus = null,
            healthServices = emptyList(),
            isLoadingHealth = false,
        )

        /** Estado de muestra con servicios cargados (previews). */
        fun previewWithHealth(): SettingsUiState = SettingsUiState(
            settings = Settings(),
            healthStatus = null,
            healthServices = listOf(
                HealthServiceStatus(
                    id = "catalog",
                    name = "Catálogo (Tidal)",
                    ok = true,
                    latencyMs = 42.0,
                    detail = null,
                ),
                HealthServiceStatus(
                    id = "stream",
                    name = "Stream (Qobuz)",
                    ok = true,
                    latencyMs = 88.0,
                    detail = null,
                ),
                HealthServiceStatus(
                    id = "cache",
                    name = "Caché",
                    ok = false,
                    latencyMs = null,
                    detail = "degraded",
                ),
            ),
            isLoadingHealth = false,
        )
    }
}
