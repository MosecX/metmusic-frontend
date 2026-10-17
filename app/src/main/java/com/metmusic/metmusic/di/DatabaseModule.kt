package com.metmusic.metmusic.di

import android.content.Context
import androidx.room.Room
import com.metmusic.metmusic.core.data.local.MetMusicDatabase
import com.metmusic.metmusic.core.data.local.dao.FavoritesDao
import com.metmusic.metmusic.core.data.local.dao.HistoryDao
import com.metmusic.metmusic.core.data.local.dao.MixFavoritesDao
import com.metmusic.metmusic.core.data.local.dao.UserPlaylistDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/** Infraestructura de persistencia local (Room). */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): MetMusicDatabase =
        Room.databaseBuilder(
            context,
            MetMusicDatabase::class.java,
            "metmusic.db",
        ).build()

    @Provides
    fun provideHistoryDao(db: MetMusicDatabase): HistoryDao = db.historyDao()

    @Provides
    fun provideFavoritesDao(db: MetMusicDatabase): FavoritesDao = db.favoritesDao()

    @Provides
    fun provideMixFavoritesDao(db: MetMusicDatabase): MixFavoritesDao = db.mixFavoritesDao()

    @Provides
    fun provideUserPlaylistDao(db: MetMusicDatabase): UserPlaylistDao = db.userPlaylistDao()
}
