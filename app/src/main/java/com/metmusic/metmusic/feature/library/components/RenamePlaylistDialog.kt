package com.metmusic.metmusic.feature.library.components

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
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Renombrado de una playlist: un campo precargado con el nombre actual.
 * "Guardar" queda deshabilitado sin nombre.
 */
@Composable
fun RenamePlaylistDialog(
    initialName: String,
    onRename: (newName: String) -> Unit,
    onDismiss: () -> Unit,
) {
    var name by remember { mutableStateOf(initialName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Renombrar playlist", style = MetMusicTextStyles.title)
        },
        text = {
            MetMusicTextField(
                value = name,
                onValueChange = { name = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = "Nombre",
            )
        },
        confirmButton = {
            TextButton(
                onClick = { onRename(name.trim()) },
                enabled = name.trim().isNotEmpty(),
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.accent),
            ) {
                Text(text = "Guardar", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
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

@Preview(name = "RenamePlaylistDialog", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun RenamePlaylistDialogPreview() {
    MetMusicTheme {
        RenamePlaylistDialog(
            initialName = "Roadtrip",
            onRename = { /* no-op en preview */ },
            onDismiss = { /* no-op en preview */ },
        )
    }
}
