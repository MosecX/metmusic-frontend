package com.metmusic.metmusic.core.network

import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.Response

/**
 * Reintenta una vez los GET no-stream que responden 5xx (espejo del
 * `_RetryInterceptor` de la app Flutter).
 *
 * Los errores de red no pasan por acá: OkHttp los lanza como `IOException`
 * antes de tener respuesta y los cubre `retryOnConnectionFailure` (default).
 * `/stream` NUNCA se reintenta: cada llamada resuelve una URL de un solo uso.
 */
class RetryInterceptor(
    private val maxAttempts: Int = 2,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        var response = chain.proceed(request)
        var attempt = 1
        while (attempt < maxAttempts && isRetryable(request, response)) {
            response.close()
            response = chain.proceed(request)
            attempt++
        }
        return response
    }

    private fun isRetryable(request: Request, response: Response): Boolean {
        val isStream = request.url.encodedPath.contains("/stream/")
        val isGet = request.method.equals("GET", ignoreCase = true)
        return !isStream && isGet && response.code >= 500
    }
}
