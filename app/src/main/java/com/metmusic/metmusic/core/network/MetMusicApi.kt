package com.metmusic.metmusic.core.network

import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.http.Body
import retrofit2.http.DELETE
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.PUT
import retrofit2.http.Query
import retrofit2.http.Url

/**
 * API de MetMusic: un método por endpoint del backend.
 *
 * Todos devuelven [ResponseBody] en crudo: el backend responde JSON
 * heterogéneo (claves alternativas, listas envueltas) y el parseo tolerante
 * vive en los repositorios (`JsonParse` + `fromJson`), sin DTOs rígidos.
 * Los paths parametrizados se arman con `ApiEndpoints` y viajan por [Url].
 */
interface MetMusicApi {

    @GET(ApiEndpoints.HEALTH)
    suspend fun health(): ResponseBody

    @GET(ApiEndpoints.SEARCH)
    suspend fun search(
        @Query("q") query: String,
        @Query("type") type: String,
        @Query("limit") limit: Int,
        @Query("offset") offset: Int,
    ): ResponseBody

    @GET
    suspend fun track(@Url url: String): ResponseBody

    @GET
    suspend fun radio(@Url url: String): ResponseBody

    @GET
    suspend fun stream(
        @Url url: String,
        @Query("quality") quality: String?,
    ): ResponseBody

    @GET
    suspend fun lyrics(@Url url: String): ResponseBody

    @GET
    suspend fun album(@Url url: String): ResponseBody

    @GET
    suspend fun artist(@Url url: String): ResponseBody

    @GET
    suspend fun playlist(@Url url: String): ResponseBody

    @GET
    suspend fun exploreHome(
        @Url url: String,
        @Query("mood") mood: String?,
    ): ResponseBody

    @GET
    suspend fun exploreNewReleases(
        @Url url: String,
        @Query("limit") limit: Int,
        @Query("offset") offset: Int,
    ): ResponseBody

    @GET
    suspend fun exploreCharts(
        @Url url: String,
        @Query("limit") limit: Int,
    ): ResponseBody

    @GET
    suspend fun exploreMoods(
        @Url url: String,
        @Query("mood") mood: String,
        @Query("limit") limit: Int,
    ): ResponseBody

    @GET
    suspend fun canvas(@Url url: String): ResponseBody

    @GET
    suspend fun userPlaylists(@Url url: String): ResponseBody

    @POST
    suspend fun createUserPlaylist(
        @Url url: String,
        @Body body: RequestBody,
    ): ResponseBody

    @GET
    suspend fun userPlaylist(@Url url: String): ResponseBody

    @PUT
    suspend fun updateUserPlaylist(
        @Url url: String,
        @Body body: RequestBody,
    ): ResponseBody

    @DELETE
    suspend fun deleteUserPlaylist(@Url url: String): ResponseBody

    @POST
    suspend fun addTracksToPlaylist(
        @Url url: String,
        @Body body: RequestBody,
    ): ResponseBody

    @DELETE
    suspend fun removeTrackFromPlaylist(@Url url: String): ResponseBody

    @PUT
    suspend fun reorderPlaylist(
        @Url url: String,
        @Body body: RequestBody,
    ): ResponseBody

    @GET
    suspend fun userHistory(
        @Url url: String,
        @Query("limit") limit: Int,
        @Query("offset") offset: Int,
    ): ResponseBody

    @POST
    suspend fun addHistory(
        @Url url: String,
        @Body body: RequestBody,
    ): ResponseBody

    @DELETE
    suspend fun clearHistory(@Url url: String): ResponseBody

    @GET
    suspend fun userFavorites(
        @Url url: String,
        @Query("limit") limit: Int,
        @Query("offset") offset: Int,
    ): ResponseBody

    @POST
    suspend fun addFavorite(@Url url: String): ResponseBody

    @DELETE
    suspend fun removeFavorite(@Url url: String): ResponseBody

    @GET
    suspend fun checkFavorites(
        @Url url: String,
        @Query("ids") ids: String,
    ): ResponseBody

    @DELETE
    suspend fun clearServerCache(@Url url: String): ResponseBody
}
