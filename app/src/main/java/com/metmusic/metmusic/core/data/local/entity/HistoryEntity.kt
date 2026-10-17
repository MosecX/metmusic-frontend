package com.metmusic.metmusic.core.data.local.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

/**
 * Una reproducción del historial local.
 *
 * [playedAt] va en epoch millis (uniforme en la DB) y [trackJson] guarda la
 * serialización de `Track.toJson()`, o null si el backend no trajo metadatos.
 */
@Entity(
    tableName = "history",
    indices = [
        Index(value = ["trackId"]),
        Index(value = ["playedAt"]),
    ],
)
data class HistoryEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0L,
    val trackId: String,
    val playedAt: Long,
    val playedMs: Long,
    val completed: Boolean,
    val trackJson: String? = null,
)
