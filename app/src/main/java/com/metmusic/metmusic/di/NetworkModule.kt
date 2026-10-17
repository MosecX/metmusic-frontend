package com.metmusic.metmusic.di

import com.metmusic.metmusic.core.data.TokenStorage
import com.metmusic.metmusic.core.network.ApiConstants
import com.metmusic.metmusic.core.network.AuthInterceptor
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import java.util.concurrent.TimeUnit
import javax.inject.Singleton
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory

/** Cableado de red de la app (Retrofit + OkHttp + AuthInterceptor). */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideJson(): Json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    @Provides
    @Singleton
    fun provideOkHttp(tokenStorage: TokenStorage): OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(ApiConstants.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .readTimeout(ApiConstants.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .writeTimeout(ApiConstants.WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
        .addInterceptor(AuthInterceptor { tokenStorage.getToken() })
        .addInterceptor(RetryInterceptor())
        .build()

    @Provides
    @Singleton
    fun provideRetrofit(okHttp: OkHttpClient, json: Json): Retrofit = Retrofit.Builder()
        .baseUrl(ApiConstants.BASE_URL)
        .client(okHttp)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()

    @Provides
    @Singleton
    fun provideMetMusicApi(retrofit: Retrofit): MetMusicApi = retrofit.create(MetMusicApi::class.java)
}
