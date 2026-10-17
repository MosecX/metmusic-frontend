package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.model.AudioQualityPreference
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.ParseApiException
import com.metmusic.metmusic.core.network.RetryInterceptor
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertInstanceOf
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class StreamRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: StreamRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = StreamRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses the stream payload and sends the quality`() = runTest {
        enqueue(body = """{"url": "https://cdn.metmusic/a.mp3", "track_id": "t1"}""")

        val info = repository.getStream("t1", AudioQualityPreference.BEST)

        assertEquals("https://cdn.metmusic/a.mp3", info.url)
        assertEquals("t1", info.trackId)
        assertEquals("/api/stream/t1?quality=best", server.takeRequest().path)
    }

    @Test
    fun `omits the quality query when there is no preference`() = runTest {
        enqueue(body = """{"url": "https://cdn.metmusic/a.mp3", "track_id": "t1"}""")

        repository.getStream("t1", null)

        assertEquals("/api/stream/t1", server.takeRequest().path)
    }

    @Test
    fun `fails with ParseApiException when the url is empty`() = runTest {
        enqueue(body = """{"track_id": "t1"}""")

        val thrown = runCatching { repository.getStream("t1", null) }.exceptionOrNull()

        assertInstanceOf(ParseApiException::class.java, thrown)
        assertEquals("El backend no devolvió una URL reproducible", thrown?.message)
    }

    @Test
    fun `never retries stream requests`() = runTest {
        enqueue(code = 500, body = """{"detail": "down"}""")

        val thrown = runCatching { repository.getStream("t1", null) }.exceptionOrNull()

        assertInstanceOf(ApiException::class.java, thrown)
        assertEquals(1, server.requestCount)
    }
}
