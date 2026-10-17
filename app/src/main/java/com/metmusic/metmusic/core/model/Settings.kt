package com.metmusic.metmusic.core.model

/** Modo de repetición del player (`ONE` es estado de cliente, no del backend). */
enum class RepeatMode(val value: String) {
    OFF("off"),
    ALL("all"),
    ONE("one"),
}

/** Preferencias de reproducción del usuario (DataStore las persiste). */
data class Settings(
    val audioQuality: AudioQualityPreference = AudioQualityPreference.DEFAULT,
    val repeatMode: RepeatMode = RepeatMode.OFF,
    val shuffle: Boolean = false,
)
