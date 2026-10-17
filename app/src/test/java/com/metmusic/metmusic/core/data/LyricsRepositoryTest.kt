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

class LyricsRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: LyricsRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = LyricsRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain lyrics payload`() = runTest {
        enqueue(body = """{"lyrics": "Hola mundo", "track_id": "t1"}""")

        val lyrics = requireNotNull(repository.getLyrics("t1"))

        assertEquals("Hola mundo", lyrics.lyrics)
        assertEquals("/api/lyrics/t1", server.takeRequest().path)
    }

    @Test
    fun `unwraps the lyrics key`() = runTest {
        enqueue(body = """{"lyrics": {"lyrics": "Verso uno", "track_id": "t2"}}""")

        assertEquals("Verso uno", requireNotNull(repository.getLyrics("t2")).lyrics)
    }

    @Test
    fun `returns null when the payload has no lyrics`() = runTest {
        enqueue(body = """{"lyrics": {"track_id": "t3"}}""")

        assertNull(repository.getLyrics("t3"))
    }

    @Test
    fun `returns null on 404`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        assertNull(repository.getLyrics("t4"))
        assertEquals(1, server.requestCount)
    }

    @Test
    fun `returns null on 401`() = runTest {
        enqueue(code = 401, body = """{"detail": "unauthorized"}""")

        assertNull(repository.getLyrics("t5"))
        assertEquals(1, server.requestCount)
    }

    @Test
    fun `retries once on 429`() = runTest {
        enqueue(code = 429, body = """{"detail": "slow down"}""")
        enqueue(body = """{"lyrics": "Recuperada"}""")

        assertEquals("Recuperada", requireNotNull(repository.getLyrics("t6")).lyrics)
        assertEquals(2, server.requestCount)
    }

    @Test
    fun `returns null when the 429 persists`() = runTest {
        enqueue(code = 429, body = """{"detail": "slow down"}""")
        enqueue(code = 429, body = """{"detail": "slow down"}""")

        assertNull(repository.getLyrics("t7"))
        assertEquals(2, server.requestCount)
    }

    @Test
    fun `returns null when the 5xx persists`() = runTest {
        enqueue(code = 500, body = "{}")
        enqueue(code = 500, body = "{}")

        assertNull(repository.getLyrics("t8"))
        assertEquals(2, server.requestCount)
    }
}
