package com.metmusic.metmusic.core.model

/**
 * Parámetros de calidad de audio soportados por el selector de Settings.
 *
 * [value] es el query param que viaja al backend; las etiquetas legibles de
 * cada opción viven en `strings.xml`.
 */
enum class AudioQualityPreference(val value: String) {
    /** Máxima calidad disponible. */
    BEST("best"),

    /** Calidad media. */
    MEDIUM("medium"),

    /** Calidad baja. */
    LOW("low");

    companion object {
        /** Valor por defecto cuando no hay preferencia guardada. */
        val DEFAULT: AudioQualityPreference = BEST

        /** Tolerante: valor desconocido o ausente cae al default. */
        fun fromValue(raw: String?): AudioQualityPreference =
            AudioQualityPreference.entries.firstOrNull { it.value == raw } ?: DEFAULT
    }
}
