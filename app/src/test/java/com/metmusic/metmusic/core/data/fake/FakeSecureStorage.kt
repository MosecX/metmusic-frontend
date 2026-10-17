package com.metmusic.metmusic.core.data.fake

import com.metmusic.metmusic.core.data.SecureStorage
import kotlinx.coroutines.flow.MutableStateFlow

/** SecureStorage en memoria para tests JVM: sin Android y sin cifrado real. */
class FakeSecureStorage : SecureStorage {

    val stored = MutableStateFlow<String?>(null)

    override fun getToken(): String? = stored.value

    override fun setToken(token: String) {
        stored.value = token
    }
}
