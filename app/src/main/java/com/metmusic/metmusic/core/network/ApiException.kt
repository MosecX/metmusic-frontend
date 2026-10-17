package com.metmusic.metmusic.core.network

import com.metmusic.metmusic.core.util.JsonParse
import java.io.IOException
import java.net.SocketTimeoutException
import kotlinx.coroutines.CancellationException
import retrofit2.HttpException

/**
 * Errores de la capa de red con los mensajes de usuario exactos del contrato
 * (port de la jerarquía de excepciones de la app Flutter).
 */
sealed class ApiException(
    message: String,
    val statusCode: Int? = null,
) : Exception(message) {

    /** Mensaje listo para mostrar en UI. */
    abstract val userMessage: String

    /** `false` cuando reintentar no tiene sentido (401, 404, 400, cancelada). */
    open val isRetryable: Boolean = true

    companion object {
        fun fromThrowable(error: Throwable): ApiException = when (error) {
            is CancellationException -> throw error
            is SocketTimeoutException -> TimeoutApiException()
            is HttpException -> fromStatus(
                error.code(),
                extractDetail(error.response()?.errorBody()?.string()),
            )
            is IOException -> NetworkApiException()
            else -> UnknownApiException(error.message)
        }

        private fun fromStatus(status: Int, detail: String?): ApiException = when (status) {
            400 -> BadRequestApiException(detail, status)
            401, 403 -> UnauthorizedApiException(status)
            404 -> NotFoundApiException(detail, status)
            429 -> ServerApiException("Demasiadas solicitudes, esperá un momento", status)
            502, 503, 504 -> ServerApiException("Error del servidor de música", status)
            else -> if (status >= 500) {
                ServerApiException(detail ?: "Error del servidor", status)
            } else {
                BadRequestApiException(detail ?: "Error inesperado", status)
            }
        }

        private fun extractDetail(body: String?): String? {
            if (body.isNullOrBlank()) return null
            val parsed = JsonParse.parse(body)
            if (parsed != null) {
                for (key in listOf("detail", "message", "error", "msg")) {
                    when (val value = parsed[key]) {
                        is String -> if (value.isNotBlank()) return value
                        is Map<*, *> -> {
                            val nested = value["message"] as? String
                            if (!nested.isNullOrBlank()) return nested
                        }
                    }
                }
            }
            // Último recurso: un cuerpo corto se muestra tal cual.
            val trimmed = body.trim()
            return trimmed.takeIf { it.length < 300 }
        }
    }
}

class NetworkApiException : ApiException("Sin conexión al servidor") {
    override val userMessage: String get() = "Sin conexión al servidor"
}

class TimeoutApiException : ApiException("El servidor tardó demasiado en responder") {
    override val userMessage: String get() = "El servidor tardó demasiado en responder"
}

class UnauthorizedApiException(statusCode: Int? = null) :
    ApiException("Token inválido o expirado. Revisá Settings.", statusCode) {
    override val userMessage: String get() = "Token inválido o expirado. Revisá Settings."
    override val isRetryable: Boolean get() = false
}

class NotFoundApiException(detail: String? = null, statusCode: Int? = null) :
    ApiException(detail ?: "Track no disponible", statusCode) {
    override val userMessage: String get() = message ?: "Track no disponible"
    override val isRetryable: Boolean get() = false
}

class BadRequestApiException(detail: String? = null, statusCode: Int? = null) :
    ApiException(detail ?: "Solicitud inválida", statusCode) {
    override val userMessage: String get() = message ?: "Solicitud inválida"
    override val isRetryable: Boolean get() = false
}

class ServerApiException(detail: String, statusCode: Int? = null) :
    ApiException(detail, statusCode) {
    override val userMessage: String get() = message ?: "Error del servidor"
}

class ParseApiException(detail: String? = null) :
    ApiException(detail ?: "Respuesta inesperada del servidor") {
    override val userMessage: String get() = "Respuesta inesperada del servidor"
}

class CancelledApiException : ApiException("Operación cancelada") {
    override val userMessage: String get() = "Operación cancelada"
    override val isRetryable: Boolean get() = false
}

class UnknownApiException(detail: String? = null) :
    ApiException(detail ?: "Ocurrió un error inesperado") {
    override val userMessage: String get() = "Ocurrió un error inesperado"
}
