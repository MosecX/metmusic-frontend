package com.metmusic.metmusic

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.metmusic.metmusic.core.ui.theme.MetMusicTheme
import com.metmusic.metmusic.navigation.MetMusicNavHost
import dagger.hilt.android.AndroidEntryPoint

/**
 * Única Activity de MetMusic: Compose de punta a punta.
 *
 * La ventana arranca con LaunchTheme (manifest) y cambia a NormalTheme antes
 * de componer, para que el fondo de ventana y el de la app coincidan durante
 * el startup (mismo esquema que la build Flutter).
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MetMusicTheme {
                MetMusicNavHost()
            }
        }
    }
}
