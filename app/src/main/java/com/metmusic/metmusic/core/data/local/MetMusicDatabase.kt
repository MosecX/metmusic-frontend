package com.metmusic.metmusic.core.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import com.metmusic.metmusic.core.data.local.dao.FavoritesDao
import com.metmusic.metmusic.core.data.local.dao.HistoryDao
import com.metmusic.metmusic.core.data.local.dao.MixFavoritesDao
import com.metmusic.metmusic.core.data.local.dao.UserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity

/** Base de datos local (Room), schema v1 exportado a `app/schemas/`. */
@Database(
    entities = [
        HistoryEntity::class,
        FavoritesEntity::class,
        MixFavoritesEntity::class,
        UserPlaylistEntity::class,
    ],
    version = 1,
    exportSchema = true,
)
abstract class MetMusicDatabase : RoomDatabase() {

    abstract fun historyDao(): HistoryDao

    abstract fun favoritesDao(): FavoritesDao

    abstract fun mixFavoritesDao(): MixFavoritesDao

    abstract fun userPlaylistDao(): UserPlaylistDao
}
