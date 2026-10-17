package com.metmusic.metmusic.core.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity

/** Acceso a las playlists propias cacheadas localmente. */
@Dao
interface UserPlaylistDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: UserPlaylistEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entities: List<UserPlaylistEntity>)

    @Query("SELECT * FROM user_playlists ORDER BY name COLLATE NOCASE ASC")
    suspend fun getAll(): List<UserPlaylistEntity>

    @Query("SELECT * FROM user_playlists WHERE id = :id LIMIT 1")
    suspend fun getById(id: String): UserPlaylistEntity?

    @Query("DELETE FROM user_playlists WHERE id = :id")
    suspend fun deleteById(id: String)

    @Query("DELETE FROM user_playlists")
    suspend fun clear()

    /** Reemplaza todo el caché en una sola transacción (evita carrera clear+insert). */
    @Transaction
    suspend fun replaceAll(entities: List<UserPlaylistEntity>) {
        clear()
        insertAll(entities)
    }
}
