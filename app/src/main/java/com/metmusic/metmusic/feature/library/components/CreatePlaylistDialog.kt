package com.metmusic.metmusic.feature.library.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.components.MetMusicTextField
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Alta de playlist propia: nombre obligatorio, descripción y portada
 * opcionales. El botón "Crear" queda deshabilitado sin nombre.
 */
@Composable
fun CreatePlaylistDialog(
    onCreate: (name: String, description: String?, coverUrl: String?) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }
    var coverUrl by remember { mutableStateOf("") }
    val spacing = LocalMetMusicSpacing.current

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Nueva playlist", style = MetMusicTextStyles.title)
        },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(spacing.md)) {
                MetMusicTextField(
                    value = name,
                    onValueChange = { name = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = "Nombre",
                )
                MetMusicTextField(
                    value = description,
                    onValueChange = { description = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = "Descripción (opcional)",
                )
                MetMusicTextField(
                    value = coverUrl,
                    onValueChange = { coverUrl = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = "URL de portada (opcional)",
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onCreate(
                        name.trim(),
                        description.trim().ifEmpty { null },
                        coverUrl.trim().ifEmpty { null },
                    )
                },
                enabled = name.trim().isNotEmpty(),
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.accent),
            ) {
                Text(text = "Crear", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
            }
        },
        dismissButton = {
            TextButton(
                onClick = onDismiss,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.textSecondary),
            ) {
                Text(text = "Cancelar", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
            }
        },
    )
}

@Preview(name = "CreatePlaylistDialog", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun CreatePlaylistDialogPreview() {
    MetMusicTheme {
        CreatePlaylistDialog(
            onCreate = { _, _, _ -> /* no-op en preview */ },
            onDismiss = { /* no-op en preview */ },
        )
    }
}
