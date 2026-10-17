package com.metmusic.metmusic

import android.Manifest
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.metmusic.metmusic.core.ui.design.MetMusicTheme
import com.metmusic.metmusic.core.ui.util.NotificationPermission
import com.metmusic.metmusic.feature.player.PlayerViewModel
import com.metmusic.metmusic.navigation.MetMusicNavHost
import dagger.hilt.android.AndroidEntryPoint

/**
 * Única Activity de MetMusic: Compose de punta a punta.
 *
 * La ventana arranca con LaunchTheme (manifest) y cambia a NormalTheme antes
 * de componer, para que el fondo de ventana y el de la app coincidan durante
 * el startup (mismo esquema que la build Flutter).
 *
 * En API 33+ pide POST_NOTIFICATIONS la primera vez que arranca una pista: si
 * se rechaza, la app reproduce igual y solo se omite la notificación.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val viewModel: PlayerViewModel = hiltViewModel()
            val state by viewModel.state.collectAsStateWithLifecycle()
            val context = LocalContext.current
            val permissionLauncher = rememberLauncherForActivityResult(
                ActivityResultContracts.RequestPermission(),
            ) { /* Rechazar silencia la notificación; la app sigue sonando. */ }
            var notificationAsked by rememberSaveable { mutableStateOf(false) }

            LaunchedEffect(state.hasTrack) {
                if (state.hasTrack &&
                    !notificationAsked &&
                    NotificationPermission.shouldRequest(context)
                ) {
                    notificationAsked = true
                    permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                }
            }

            MetMusicTheme {
                MetMusicNavHost()
            }
        }
    }
}
