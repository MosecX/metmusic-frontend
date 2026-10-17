package com.metmusic.metmusic.core.data

/**
 * Almacenamiento seguro de secretos (EncryptedSharedPreferences en producción).
 *
 * La API es sincrónica a propósito: el interceptor HTTP no puede ser suspend
 * y SharedPreferences resuelve en memoria tras la primera carga.
 */
interface SecureStorage {

    fun getToken(): String?

    fun setToken(token: String)
}
