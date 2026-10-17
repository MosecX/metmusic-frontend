package com.metmusic.metmusic.core.network

import okhttp3.Interceptor
import okhttp3.Response

/**
 * Agrega `Authorization: Bearer <token>` a los endpoints `/api` (menos `/api/health`).
 *
 * Misma regla que la app Flutter: si el token está vacío, el request sale sin
 * header (el backend responde 401 y la UI lo traduce).
 */
class AuthInterceptor(private val tokenProvider: () -> String) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val path = request.url.encodedPath
        val needsAuth = path.startsWith("/api") && path != "/api/health"
        val token = tokenProvider().trim()

        if (needsAuth && token.isNotEmpty()) {
            val authorized = request.newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
            return chain.proceed(authorized)
        }
        return chain.proceed(request)
    }
}
