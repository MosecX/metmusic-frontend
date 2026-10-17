package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.ApiConstants
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Token Bearer de la app, respaldado por el storage cifrado.
 *
 * En el primer arranque (storage vacío) persiste el token default y lo
 * devuelve, para que el resto del código no note la migración.
 */
@Singleton
class TokenStorage @Inject constructor(
    private val secureStorage: SecureStorage,
) {
    fun getToken(): String {
        val stored = secureStorage.getToken()
        if (stored != null) return stored
        secureStorage.setToken(ApiConstants.DEFAULT_API_TOKEN)
        return ApiConstants.DEFAULT_API_TOKEN
    }

    fun setToken(token: String) {
        secureStorage.setToken(token)
    }
}
