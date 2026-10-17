package com.metmusic.metmusic.core.data.local.security

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.metmusic.metmusic.core.data.SecureStorage
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

private const val PREFS_NAME = "metmusic_secure"
private const val KEY_API_TOKEN = "api_token"

/**
 * Implementación real con EncryptedSharedPreferences (MasterKey AES256_GCM).
 *
 * Es la única clase de este archivo con `Context` y no expone el archivo de
 * prefs ni su nombre fuera de acá. El `prefs` es lazy: no hay I/O en
 * construcción, el primer uso paga la carga.
 */
@Suppress("DEPRECATION")
@Singleton
class EncryptedPrefsSecureStorage @Inject constructor(
    @ApplicationContext private val context: Context,
) : SecureStorage {

    private val prefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    override fun getToken(): String? =
        prefs.getString(KEY_API_TOKEN, null)?.takeIf { it.isNotBlank() }

    override fun setToken(token: String) {
        prefs.edit().putString(KEY_API_TOKEN, token).apply()
    }
}
