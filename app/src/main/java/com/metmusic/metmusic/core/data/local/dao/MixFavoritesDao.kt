package com.metmusic.metmusic.core.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity

/** Acceso a los mixes (radios) favoritos locales. */
@Dao
interface MixFavoritesDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: MixFavoritesEntity)

    @Query("DELETE FROM mix_favorites WHERE trackId = :trackId")
    suspend fun deleteByTrackId(trackId: String)

    @Query("SELECT EXISTS(SELECT 1 FROM mix_favorites WHERE trackId = :trackId)")
    suspend fun exists(trackId: String): Boolean

    @Query("SELECT * FROM mix_favorites ORDER BY addedAt DESC")
    suspend fun getAll(): List<MixFavoritesEntity>

    @Query("DELETE FROM mix_favorites")
    suspend fun clear()
}
