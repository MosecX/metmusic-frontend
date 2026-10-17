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
import androidx.compose.material.icons.outlined.Warning
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Estado de error centrado de MetMusic: icono en `danger`, mensaje y acción
 * de reintento en acento.
 */
@Composable
fun MetMusicErrorState(
    message: String,
    onRetry: () -> Unit,
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
            imageVector = Icons.Outlined.Warning,
            contentDescription = null,
            colorFilter = ColorFilter.tint(MetMusicColors.danger),
            modifier = Modifier.size(48.dp),
        )
        Spacer(modifier = Modifier.height(spacing.md))
        BasicText(
            text = message,
            style = MetMusicTextStyles.body.copy(textAlign = TextAlign.Center),
        )
        Spacer(modifier = Modifier.height(spacing.lg))
        BasicText(
            text = "Reintentar",
            style = MetMusicTextStyles.button.copy(color = MetMusicColors.accent),
            modifier = Modifier
                .clickable(onClick = onRetry)
                .padding(horizontal = spacing.md, vertical = spacing.sm),
        )
    }
}

@Preview(name = "MetMusicErrorState", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicErrorStatePreview() {
    MetMusicTheme {
        MetMusicErrorState(
            message = "No se pudo conectar con el servidor.",
            onRetry = {},
        )
    }
}
