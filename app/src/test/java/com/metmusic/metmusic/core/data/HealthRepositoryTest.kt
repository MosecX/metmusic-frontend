package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertInstanceOf
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class HealthRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: HealthRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = HealthRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses the health payload`() = runTest {
        enqueue(body = """{"ok": true, "status": "ok", "version": "1.0.0"}""")

        val health = repository.check()

        assertTrue(health.ok)
        assertEquals("1.0.0", health.version)
        assertEquals("/api/health", server.takeRequest().path)
    }

    @Test
    fun `parses the service list`() = runTest {
        enqueue(body = """{"status": "ok", "services": [{"name": "catalog", "status": "ok"}]}""")

        val health = repository.check()

        assertTrue(health.ok)
        assertEquals(1, health.services.size)
    }

    @Test
    fun `clears the server cache with a delete`() = runTest {
        enqueue(body = """{"deleted": 1, "pattern": "*"}""")

        repository.clearServerCache()

        val request = server.takeRequest()
        assertEquals("DELETE", request.method)
        assertEquals("/api/cache", request.path)
    }

    @Test
    fun `does not retry a failing delete`() = runTest {
        enqueue(code = 500, body = "{}")

        val thrown = runCatching { repository.clearServerCache() }.exceptionOrNull()

        assertInstanceOf(ApiException::class.java, thrown)
        assertEquals(1, server.requestCount)
    }
}
