package com.metmusic.metmusic.di

import android.content.Context
import com.metmusic.metmusic.core.data.SecureStorage
import com.metmusic.metmusic.core.data.SettingsStorage
import com.metmusic.metmusic.core.data.local.security.EncryptedPrefsSecureStorage
import com.metmusic.metmusic.core.data.local.settings.DataStoreSettingsStorage
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

/** Implementaciones reales de los storages (DataStore + EncryptedSharedPreferences). */
@Module
@InstallIn(SingletonComponent::class)
object StorageModule {

    @Provides
    @Singleton
    fun provideSettingsStorage(@ApplicationContext context: Context): SettingsStorage =
        DataStoreSettingsStorage(context)

    @Provides
    @Singleton
    fun provideSecureStorage(@ApplicationContext context: Context): SecureStorage =
        EncryptedPrefsSecureStorage(context)
}
