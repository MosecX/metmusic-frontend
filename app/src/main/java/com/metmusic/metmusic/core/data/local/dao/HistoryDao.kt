package com.metmusic.metmusic.core.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity

/** Acceso al historial local (más reciente primero). */
@Dao
interface HistoryDao {

    @Insert
    suspend fun insert(entity: HistoryEntity): Long

    @Query("SELECT * FROM history ORDER BY playedAt DESC LIMIT :limit")
    suspend fun getAll(limit: Int): List<HistoryEntity>

    @Query("SELECT * FROM history ORDER BY playedAt DESC")
    suspend fun getAllNoLimit(): List<HistoryEntity>

    @Query("SELECT * FROM history ORDER BY playedAt DESC LIMIT 1")
    suspend fun latest(): HistoryEntity?

    @Query(
        "DELETE FROM history WHERE id NOT IN " +
            "(SELECT id FROM history ORDER BY playedAt DESC LIMIT :maxEntries)",
    )
    suspend fun trimTo(maxEntries: Int)

    @Query("DELETE FROM history")
    suspend fun clear()

    @Query("SELECT COUNT(*) FROM history")
    suspend fun count(): Int
}
