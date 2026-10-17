package com.metmusic.metmusic.navigation

import kotlinx.serialization.Serializable

/** Rutas tipadas de Navigation Compose. Las próximas pantallas se suman acá. */
@Serializable
sealed interface Routes {
    @Serializable
    data object Search : Routes
}
