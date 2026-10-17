package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.NotFoundApiException
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

class TrackRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: TrackRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = TrackRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain track payload`() = runTest {
        enqueue(body = """{"track_id": "t1", "title": "Tema", "artist": "Banda"}""")

        val track = repository.getTrack("t1")

        assertEquals("t1", track.trackId)
        assertEquals("Tema", track.title)
        assertEquals("Banda", track.artist)
    }

    @Test
    fun `unwraps the track key and accepts the id alias`() = runTest {
        enqueue(body = """{"track": {"id": "t2", "title": "Otra"}}""")

        val track = repository.getTrack("t2")

        assertEquals("t2", track.trackId)
        assertEquals("Otra", track.title)
        assertEquals("/api/tracks/t2", server.takeRequest().path)
    }

    @Test
    fun `parses track details with the duration alias`() = runTest {
        enqueue(body = """{"id": "t3", "title": "Detalle", "duration": 215, "bpm": 128.5}""")

        val details = repository.getTrackDetails("t3")

        assertEquals("t3", details.trackId)
        assertEquals(215, details.durationSeconds)
        assertEquals(128.5, details.bpm ?: 0.0)
    }

    @Test
    fun `maps a 404 to NotFoundApiException`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        val thrown = runCatching { repository.getTrack("nope") }.exceptionOrNull()

        assertInstanceOf(NotFoundApiException::class.java, thrown)
        assertEquals(1, server.requestCount)
    }
}
