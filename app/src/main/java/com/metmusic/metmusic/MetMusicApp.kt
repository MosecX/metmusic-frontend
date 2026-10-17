package com.metmusic.metmusic

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Aplicación MetMusic. Hilt arma el grafo de dependencias de toda la app y los
 * puntos de entrada (@AndroidEntryPoint) de producción y tests.
 */
@HiltAndroidApp
class MetMusicApp : Application()
