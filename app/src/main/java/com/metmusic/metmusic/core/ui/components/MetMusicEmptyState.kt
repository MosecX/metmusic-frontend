package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.text.BasicText
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Search
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Estado vacío centrado de MetMusic: icono, título, subtítulo y acción
 * opcionales.
 */
@Composable
fun MetMusicEmptyState(
    title: String,
    subtitle: String? = null,
    icon: ImageVector = Icons.Outlined.Search,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(spacing.pagePadding),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Image(
            imageVector = icon,
            contentDescription = null,
            colorFilter = ColorFilter.tint(MetMusicColors.textTertiary),
            modifier = Modifier.size(48.dp),
        )
        Spacer(modifier = Modifier.height(spacing.md))
        BasicText(
            text = title,
            style = MetMusicTextStyles.sectionTitle.copy(textAlign = TextAlign.Center),
        )
        if (!subtitle.isNullOrEmpty()) {
            Spacer(modifier = Modifier.height(spacing.xs))
            BasicText(
                text = subtitle,
                style = MetMusicTextStyles.subtitle.copy(textAlign = TextAlign.Center),
            )
        }
        if (actionLabel != null && onAction != null) {
            Spacer(modifier = Modifier.height(spacing.lg))
            BasicText(
                text = actionLabel,
                style = MetMusicTextStyles.button,
                modifier = Modifier
                    .clickable(onClick = onAction)
                    .padding(horizontal = spacing.md, vertical = spacing.sm),
            )
        }
    }
}

@Preview(name = "MetMusicEmptyState", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicEmptyStatePreview() {
    MetMusicTheme {
        MetMusicEmptyState(title = "Buscá en MetMusic")
    }
}

@Preview(name = "MetMusicEmptyState con acción", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicEmptyStateActionPreview() {
    MetMusicTheme {
        MetMusicEmptyState(
            title = "Buscá en MetMusic",
            subtitle = "Artistas, álbumes, canciones o playlists.",
            actionLabel = "Reintentar",
            onAction = { /* no-op en preview */ },
        )
    }
}
