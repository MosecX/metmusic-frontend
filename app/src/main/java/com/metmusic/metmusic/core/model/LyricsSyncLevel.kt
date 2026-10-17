package com.metmusic.metmusic.core.model

/**
 * Nivel de sincronía reportado por el backend (`sync_level`).
 *
 * Es el campo que decide CÓMO renderizar y puede variar por track y por
 * request (depende de qué fuente gana): nunca se asume fijo, se lee siempre
 * de la respuesta.
 */
enum class LyricsSyncLevel {
    /** Karaoke por palabra (`words` con `time_ms` + `duration_ms`). */
    WORD,

    /** Resalta la línea actual. */
    LINE,

    /** Sólo texto plano, sin sincronía. */
    NONE,
}
