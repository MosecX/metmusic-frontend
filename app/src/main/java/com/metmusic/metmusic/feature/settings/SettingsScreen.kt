package com.metmusic.metmusic.feature.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.model.Settings
import com.metmusic.metmusic.core.network.ApiConstants
import com.metmusic.metmusic.core.ui.components.MetMusicDivider
import com.metmusic.metmusic.core.ui.components.MetMusicSectionHeader
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Ajustes (minimal de 6A-2, solo lectura): versión, backend y calidad de
 * audio actual. La edición (calidad, health, limpiar caché) llega en 6D.
 *
 * El padding horizontal lo aportan cada fila y los componentes compartidos
 * ([MetMusicSectionHeader], [MetMusicDivider]) para que todo quede alineado
 * al `pagePadding`.
 */
@Composable
fun SettingsScreen(
    modifier: Modifier = Modifier,
    viewModel: SettingsViewModel = hiltViewModel(),
) {
    val settings by viewModel.settings.collectAsStateWithLifecycle()
    SettingsScreenContent(settings = settings, modifier = modifier)
}

/** Composición pura de Ajustes (sin ViewModel), lista para previews. */
@Composable
fun SettingsScreenContent(
    settings: Settings,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState()),
    ) {
        Text(
            text = "Ajustes",
            style = MetMusicTextStyles.largeTitle,
            color = MetMusicColors.textPrimary,
            modifier = Modifier.padding(
                start = spacing.pagePadding,
                end = spacing.pagePadding,
                top = spacing.pagePadding,
            ),
        )
        Spacer(modifier = Modifier.height(spacing.sectionGap))
        MetMusicSectionHeader(title = "Acerca de")
        SettingsRow(label = "Versión", value = APP_VERSION)
        MetMusicDivider()
        SettingsRow(label = "Backend", value = ApiConstants.BASE_URL)
        Spacer(modifier = Modifier.height(spacing.sectionGap))
        MetMusicSectionHeader(title = "Reproducción")
        SettingsRow(
            label = "Calidad de audio",
            value = audioQualityLabel(settings.audioQuality),
        )
    }
}

/** Fila etiqueta/valor de una sección de Ajustes. */
@Composable
private fun SettingsRow(
    label: String,
    value: String,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(
                start = spacing.pagePadding,
                end = spacing.pagePadding,
                top = spacing.md,
                bottom = spacing.md,
            ),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = label,
            style = MetMusicTextStyles.body,
            color = MetMusicColors.textPrimary,
        )
        Text(
            text = value,
            style = MetMusicTextStyles.bodyLight,
            color = MetMusicColors.textSecondary,
            textAlign = TextAlign.End,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
        )
    }
}

/**
 * Versión mostrada en Ajustes. `app/build.gradle.kts` (línea 40) usa
 * "0.1.0-native" como default de `versionName` y `gradle.properties` (línea
 * 20) fija el mismo valor; el proyecto no habilita ni referencia
 * `BuildConfig`, así que se usa el literal (decisión declarada en 6A-2).
 */
private const val APP_VERSION = "0.1.0-native"

/**
 * `AudioQualityPreference` solo expone `value` y no hay strings.xml con
 * labels legibles, así que el mapeo vive acá (decisión declarada en 6A-2).
 */
private fun audioQualityLabel(quality: AudioQualityPreference): String = when (quality) {
    AudioQualityPreference.BEST -> "Máxima"
    AudioQualityPreference.MEDIUM -> "Media"
    AudioQualityPreference.LOW -> "Baja"
}

@Preview(name = "SettingsScreen calidad máxima", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun SettingsScreenBestPreview() {
    MetMusicTheme {
        SettingsScreenContent(settings = Settings())
    }
}

@Preview(name = "SettingsScreen calidad baja", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun SettingsScreenLowPreview() {
    MetMusicTheme {
        SettingsScreenContent(
            settings = Settings(audioQuality = AudioQualityPreference.LOW),
        )
    }
}
