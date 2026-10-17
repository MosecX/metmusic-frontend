package com.metmusic.metmusic.core.data.local.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Un mix (radio) favorito local.
 *
 * No se serializa el modelo a JSON: los campos van como columnas para no
 * acoplar la tabla a `RadioMix`.
 */
@Entity(tableName = "mix_favorites")
data class MixFavoritesEntity(
    @PrimaryKey val trackId: String,
    val mixId: String,
    val title: String,
    val subTitle: String? = null,
    val description: String? = null,
    val imageUrl: String? = null,
    val addedAt: Long,
)
