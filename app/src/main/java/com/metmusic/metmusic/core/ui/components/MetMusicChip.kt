package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.LocalMetMusicRadius
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Chip de filtro de MetMusic: pill con acento de fondo cuando está
 * seleccionado y `controlFill` cuando no.
 */
@Composable
fun MetMusicChip(
    label: String,
    selected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        modifier = modifier,
        label = {
            Text(
                text = label,
                style = MetMusicTextStyles.label,
                color = if (selected) Color.Black else MetMusicColors.textPrimary,
            )
        },
        shape = RoundedCornerShape(LocalMetMusicRadius.current.chip),
        colors = FilterChipDefaults.filterChipColors(
            containerColor = MetMusicColors.controlFill,
            labelColor = MetMusicColors.textPrimary,
            selectedContainerColor = MetMusicColors.accent,
            selectedLabelColor = Color.Black,
        ),
    )
}

@Preview(name = "MetMusicChip seleccionado", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicChipSelectedPreview() {
    MetMusicTheme {
        MetMusicChip(
            label = "Canciones",
            selected = true,
            onClick = { /* no-op en preview */ },
        )
    }
}

@Preview(name = "MetMusicChip sin seleccionar", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicChipUnselectedPreview() {
    MetMusicTheme {
        MetMusicChip(
            label = "Álbumes",
            selected = false,
            onClick = { /* no-op en preview */ },
        )
    }
}
