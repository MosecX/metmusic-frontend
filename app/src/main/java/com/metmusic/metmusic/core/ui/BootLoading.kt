package com.metmusic.metmusic.core.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.metmusic.metmusic.R
import com.metmusic.metmusic.core.ui.theme.MetMusicColors
import com.metmusic.metmusic.core.ui.theme.MetMusicTextStyles
import com.metmusic.metmusic.core.ui.theme.MetMusicTheme

/**
 * Pantalla de arranque: spinner 28 dp (acento #BF5AF2) + "MetMusic" + 
 * "Iniciando…". Espejo del _BootLoading de Flutter.
 */
@Composable
fun BootLoading(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .fillMaxSize()
            .background(MetMusicColors.background),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator(
                modifier = Modifier.size(28.dp),
                color = MetMusicColors.accent,
                strokeWidth = 2.5.dp,
            )
            Spacer(Modifier.height(18.dp))
            Text(
                text = stringResource(R.string.app_name),
                style = MetMusicTextStyles.headline,
            )
            Spacer(Modifier.height(6.dp))
            Text(
                text = stringResource(R.string.boot_initializing),
                style = MetMusicTextStyles.subtitle,
            )
        }
    }
}

@Preview(name = "BootLoading", showBackground = true, backgroundColor = 0xFF000000)
@Composable
private fun BootLoadingPreview() {
    MetMusicTheme {
        BootLoading()
    }
}
