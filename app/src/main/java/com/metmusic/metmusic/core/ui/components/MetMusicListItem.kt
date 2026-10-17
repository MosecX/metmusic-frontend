package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.BasicText
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import androidx.compose.ui.tooling.preview.PreviewParameterProvider
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Fila de lista de MetMusic: leading (artwork o icono), título con subtítulo
 * opcional a una línea, trailing opcional (ej. duración) y click opcional.
 * Touch target mínimo de 56 dp.
 */
@Composable
fun MetMusicListItem(
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
    leadingUrl: String? = null,
    leadingIcon: ImageVector? = null,
    trailingContent: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val spacing = LocalMetMusicSpacing.current
    val rowModifier = modifier
        .fillMaxWidth()
        .heightIn(min = 56.dp)
        .then(
            if (onClick != null) {
                Modifier.clickable(onClick = onClick)
            } else {
                Modifier
            },
        )
        .padding(horizontal = spacing.lg, vertical = spacing.sm)
    Row(
        modifier = rowModifier,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (leadingUrl != null) {
            MetMusicArtwork(url = leadingUrl, size = 56.dp)
        } else if (leadingIcon != null) {
            Image(
                imageVector = leadingIcon,
                contentDescription = null,
                colorFilter = ColorFilter.tint(MetMusicColors.textSecondary),
                modifier = Modifier.size(24.dp),
            )
        }
        if (leadingUrl != null || leadingIcon != null) {
            Spacer(modifier = Modifier.width(spacing.md))
        }
        Column(modifier = Modifier.weight(1f)) {
            BasicText(
                text = title,
                style = MetMusicTextStyles.rowTitle,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (!subtitle.isNullOrEmpty()) {
                BasicText(
                    text = subtitle,
                    style = MetMusicTextStyles.rowSubtitle,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (trailing != null || trailingContent != null) {
            Spacer(modifier = Modifier.width(spacing.md))
        }
        if (trailing != null) {
            BasicText(
                text = trailing,
                style = MetMusicTextStyles.rowTrailing,
            )
        }
        trailingContent?.invoke()
    }
}

/** Datos de una variante del preview de [MetMusicListItem]. */
private data class ListItemPreviewData(
    val title: String,
    val subtitle: String? = null,
    val trailing: String? = null,
    val leadingUrl: String? = null,
)

private class ListItemPreviewProvider : PreviewParameterProvider<ListItemPreviewData> {
    override val values: Sequence<ListItemPreviewData> = sequenceOf(
        ListItemPreviewData(title = "Solo título"),
        ListItemPreviewData(title = "Con subtítulo", subtitle = "Daft Punk · Discovery"),
        ListItemPreviewData(title = "Con trailing", subtitle = "Daft Punk", trailing = "5:20"),
        ListItemPreviewData(
            title = "Con artwork",
            subtitle = "Daft Punk · Discovery",
            leadingUrl = "https://example.com/artwork.jpg",
        ),
    )
}

@Preview(name = "MetMusicListItem", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicListItemPreview(
    @PreviewParameter(ListItemPreviewProvider::class) data: ListItemPreviewData,
) {
    MetMusicTheme {
        MetMusicListItem(
            title = data.title,
            subtitle = data.subtitle,
            trailing = data.trailing,
            leadingUrl = data.leadingUrl,
            onClick = { /* no-op en preview */ },
        )
    }
}
