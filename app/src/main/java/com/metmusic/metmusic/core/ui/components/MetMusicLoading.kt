package com.metmusic.metmusic.core.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.core.ui.design.MetMusicColors
import com.metmusic.metmusic.core.ui.design.MetMusicTheme

/**
 * Spinner centrado de MetMusic: acento y trazo de 2.5 dp sobre el área que
 * le deje el caller.
 */
@Composable
fun MetMusicLoading(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        CircularProgressIndicator(
            color = MetMusicColors.accent,
            strokeWidth = 2.5.dp,
        )
    }
}

@Preview(name = "MetMusicLoading", showBackground = true, backgroundColor = 0xFF000000, heightDp = 200)
@Composable
private fun MetMusicLoadingPreview() {
    MetMusicTheme {
        MetMusicLoading()
    }
}
