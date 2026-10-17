package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.HorizontalDivider
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.LocalMetMusicSpacing
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Separador de MetMusic: línea de 0.5 dp en `separator`, con padding de
 * página a los costados.
 */
@Composable
fun MetMusicDivider(modifier: Modifier = Modifier) {
    HorizontalDivider(
        modifier = modifier.padding(horizontal = LocalMetMusicSpacing.current.pagePadding),
        thickness = 0.5.dp,
        color = MetMusicColors.separator,
    )
}

@Preview(name = "MetMusicDivider", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun MetMusicDividerPreview() {
    MetMusicTheme {
        MetMusicDivider()
    }
}
