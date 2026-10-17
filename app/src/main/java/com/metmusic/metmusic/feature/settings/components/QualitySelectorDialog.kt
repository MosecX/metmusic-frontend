package com.metmusic.metmusic.feature.settings.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.RadioButton
import androidx.compose.material3.RadioButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Selector de calidad de audio: tap en una opción aplica y cierra (sin botón
 * "Aplicar"); "Cancelar" descarta.
 */
@Composable
fun QualitySelectorDialog(
    current: AudioQualityPreference,
    onSelect: (AudioQualityPreference) -> Unit,
    onDismiss: () -> Unit,
) {
    val spacing = LocalMetMusicSpacing.current
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Calidad de audio", style = MetMusicTextStyles.title)
        },
        text = {
            Column {
                AudioQualityPreference.entries.forEach { option ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onSelect(option) }
                            .padding(vertical = spacing.sm),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        RadioButton(
                            selected = option == current,
                            onClick = null,
                            colors = RadioButtonDefaults.colors(
                                selectedColor = MetMusicColors.accent,
                                unselectedColor = MetMusicColors.textSecondary,
                            ),
                        )
                        Spacer(modifier = Modifier.width(spacing.sm))
                        Text(
                            text = option.label(),
                            style = MetMusicTextStyles.body,
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.textSecondary),
            ) {
                Text(text = "Cancelar", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
            }
        },
    )
}

/** Etiqueta legible de una opción de calidad (el enum solo expone `value`). */
internal fun AudioQualityPreference.label(): String = when (this) {
    AudioQualityPreference.BEST -> "Máxima (HI_RES / FLAC)"
    AudioQualityPreference.MEDIUM -> "Media (LOSSLESS / CD)"
    AudioQualityPreference.LOW -> "Baja (ahorro de datos)"
}

@Preview(name = "QualitySelectorDialog", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun QualitySelectorDialogPreview() {
    MetMusicTheme {
        QualitySelectorDialog(
            current = AudioQualityPreference.BEST,
            onSelect = { /* no-op en preview */ },
            onDismiss = { /* no-op en preview */ },
        )
    }
}
