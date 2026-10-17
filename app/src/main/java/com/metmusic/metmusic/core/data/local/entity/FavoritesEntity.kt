package com.metmusic.metmusic.core.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Un track favorito local.
 *
 * [trackJson] guarda la serialización de `Track.toJson()` y [addedAt] el
 * epoch millis en que se agregó (los favoritos remotos usan el orden de
 * llegada al sincronizar).
 */
@Entity(tableName = "favorites")
data class FavoritesEntity(
    @PrimaryKey val trackId: String,
    val trackJson: String,
    val addedAt: Long,
)
