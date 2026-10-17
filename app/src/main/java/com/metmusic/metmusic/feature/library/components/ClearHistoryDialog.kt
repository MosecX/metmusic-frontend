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

/** Confirmación de borrado total del historial (acción destructiva). */
@Composable
fun ClearHistoryDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Limpiar historial", style = MetMusicTextStyles.title)
        },
        text = {
            Text(
                text = "¿Borrar todo el historial de reproducción? Esta acción no se puede deshacer.",
                style = MetMusicTextStyles.subtitle,
            )
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                colors = ButtonDefaults.textButtonColors(contentColor = MetMusicColors.danger),
            ) {
                Text(text = "Limpiar", style = MetMusicTextStyles.button.copy(color = Color.Unspecified))
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

@Preview(name = "ClearHistoryDialog", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun ClearHistoryDialogPreview() {
    MetMusicTheme {
        ClearHistoryDialog(
            onConfirm = { /* no-op en preview */ },
            onDismiss = { /* no-op en preview */ },
        )
    }
}
