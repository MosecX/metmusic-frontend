package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Encabezado de sección de MetMusic: título y acción opcional alineada a la
 * derecha, con padding de página.
 */
@Composable
fun MetMusicSectionHeader(
    title: String,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = spacing.pagePadding, vertical = spacing.md),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        BasicText(
            text = title,
            style = MetMusicTextStyles.sectionTitle,
        )
        if (actionLabel != null && onAction != null) {
            Spacer(modifier = Modifier.weight(1f))
            BasicText(
                text = actionLabel,
                style = MetMusicTextStyles.label.copy(color = MetMusicColors.accent),
                modifier = Modifier
                    .clickable(onClick = onAction)
                    .padding(spacing.xs),
            )
        }
    }
}

@Preview(name = "MetMusicSectionHeader", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicSectionHeaderPreview() {
    MetMusicTheme {
        MetMusicSectionHeader(title = "Canciones")
    }
}

@Preview(name = "MetMusicSectionHeader con acción", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicSectionHeaderActionPreview() {
    MetMusicTheme {
        MetMusicSectionHeader(
            title = "Canciones",
            actionLabel = "Ver todo",
            onAction = { /* no-op en preview */ },
        )
    }
}
