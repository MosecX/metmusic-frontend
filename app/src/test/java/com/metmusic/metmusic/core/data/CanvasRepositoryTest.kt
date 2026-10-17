package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class CanvasRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: CanvasRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = CanvasRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain canvas payload`() = runTest {
        enqueue(body = """{"url": "https://cdn/canvas.mp4", "provider": "spotify", "kind": "mp4"}""")

        val canvas = requireNotNull(repository.getCanvas("t1"))

        assertEquals("https://cdn/canvas.mp4", canvas.url)
        assertEquals("spotify", canvas.provider)
        assertEquals("/api/canvas/t1", server.takeRequest().path)
    }

    @Test
    fun `unwraps the canvas key`() = runTest {
        enqueue(body = """{"canvas": {"url": "https://cdn/otro.mp4"}}""")

        assertEquals("https://cdn/otro.mp4", requireNotNull(repository.getCanvas("t2")).url)
    }

    @Test
    fun `returns null when the url is empty`() = runTest {
        enqueue(body = """{"provider": "spotify"}""")

        assertNull(repository.getCanvas("t3"))
    }

    @Test
    fun `returns null on 404`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        assertNull(repository.getCanvas("t4"))
        assertEquals(1, server.requestCount)
    }
}
