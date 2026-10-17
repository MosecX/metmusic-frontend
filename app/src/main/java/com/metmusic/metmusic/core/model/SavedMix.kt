package com.metmusic.metmusic.core.model

/**
 * Un mix (radio) guardado: el track semilla que lo generó y su metadata.
 *
 * Es el par que se persiste en la tabla `mix_favorites`.
 */
data class SavedMix(
    val trackId: String,
    val mix: RadioMix,
)
