package com.metmusic.metmusic.core.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Una playlist propia cacheada localmente.
 *
 * [tracksJson] es un array JSON de `Track.toJson()` y [cachedAt] el epoch
 * millis de la última sincronización con el backend.
 */
@Entity(tableName = "user_playlists")
data class UserPlaylistEntity(
    @PrimaryKey val id: String,
    val name: String,
    val description: String? = null,
    val coverUrl: String? = null,
    val trackCount: Int? = null,
    val tracksJson: String,
    val createdAt: String? = null,
    val updatedAt: String? = null,
    val cachedAt: Long,
)
