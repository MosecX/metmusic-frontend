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

class RadioRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: RadioRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = RadioRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses the station payload`() = runTest {
        enqueue(
            body = """{"track_id": "seed", "mix": {"id": "m1", "title": "Mix"}, "items": [{"track_id": "t1", "title": "Primera"}]}""",
        )

        val station = requireNotNull(repository.getRadio("seed"))

        assertEquals("seed", station.trackId)
        assertEquals(1, station.items.size)
        assertEquals("t1", station.items.first().trackId)
        assertEquals("/api/tracks/seed/radio", server.takeRequest().path)
    }

    @Test
    fun `returns null when the station has no items`() = runTest {
        enqueue(body = """{"track_id": "seed", "mix": {"id": "m1"}, "items": []}""")

        assertNull(repository.getRadio("seed"))
    }

    @Test
    fun `returns null on 404`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        assertNull(repository.getRadio("seed"))
        assertEquals(1, server.requestCount)
    }
}
