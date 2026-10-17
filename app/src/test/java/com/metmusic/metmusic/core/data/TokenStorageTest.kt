package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeSecureStorage
import com.metmusic.metmusic.core.network.ApiConstants
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Test

class TokenStorageTest {

    private val secureStorage = FakeSecureStorage()
    private val tokenStorage = TokenStorage(secureStorage)

    @Test
    fun `returns the persisted token when present`() {
        secureStorage.setToken("stored-token")

        assertEquals("stored-token", tokenStorage.getToken())
    }

    @Test
    fun `persists and returns the default when storage is empty`() {
        assertNull(secureStorage.getToken())

        val token = tokenStorage.getToken()

        assertEquals(ApiConstants.DEFAULT_API_TOKEN, token)
        assertEquals(ApiConstants.DEFAULT_API_TOKEN, secureStorage.getToken())
    }

    @Test
    fun `setToken overrides previous value`() {
        tokenStorage.setToken("custom-token")

        assertEquals("custom-token", tokenStorage.getToken())
    }
}
