package com.metmusic.metmusic.core.network

import okhttp3.ResponseBody
import retrofit2.http.GET
import retrofit2.http.Query

/**
 * API de MetMusic.
 *
 * `search` devuelve [ResponseBody] en crudo: el backend responde JSON
 * heterogéneo (claves alternativas, listas envueltas), y devolver el cuerpo
 * para parsearlo con `JsonParse` evita DTOs rígidos y espeja el parser
 * tolerante de la app Flutter. NO agregar otros endpoints acá hasta que otra
 * fase los use.
 */
interface MetMusicApi {

    @GET(ApiEndpoints.SEARCH)
    suspend fun search(
        @Query("q") query: String,
        @Query("type") type: String,
        @Query("limit") limit: Int,
        @Query("offset") offset: Int,
    ): ResponseBody
}
