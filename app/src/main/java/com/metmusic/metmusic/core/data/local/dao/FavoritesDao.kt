package com.metmusic.metmusic.core.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity

/** Acceso a los favoritos locales. */
@Dao
interface FavoritesDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: FavoritesEntity)

    @Query("DELETE FROM favorites WHERE trackId = :trackId")
    suspend fun deleteByTrackId(trackId: String)

    @Query("SELECT EXISTS(SELECT 1 FROM favorites WHERE trackId = :trackId)")
    suspend fun exists(trackId: String): Boolean

    @Query("SELECT * FROM favorites ORDER BY addedAt DESC")
    suspend fun getAll(): List<FavoritesEntity>

    @Query("DELETE FROM favorites")
    suspend fun clear()

    @Query("SELECT COUNT(*) FROM favorites")
    suspend fun count(): Int
}
