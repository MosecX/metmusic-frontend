package com.metmusic.metmusic.feature.library.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/** Confirmación de borrado de una playlist (acción destructiva). */
@Composable
fun DeletePlaylistDialog(
    playlistName: String,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Eliminar playlist", style = MetMusicTextStyles.title)
        },
        text = {
            Text(
                text = "¿Eliminar \"$playlistName\"? Esta acción no se puede deshacer.",
                style = MetMusicTextStyles.subtitle,
            )
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.danger),
            ) {
                Text(text = "Eliminar", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
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

@Preview(name = "DeletePlaylistDialog", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun DeletePlaylistDialogPreview() {
    MetMusicTheme {
        DeletePlaylistDialog(
            playlistName = "Roadtrip",
            onConfirm = { /* no-op en preview */ },
            onDismiss = { /* no-op en preview */ },
        )
    }
}
