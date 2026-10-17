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

class PlaylistRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: PlaylistRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = PlaylistRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain playlist payload`() = runTest {
        enqueue(body = """{"uuid": "u1", "title": "Mix"}""")

        val playlist = repository.getPlaylist("u1")

        assertEquals("u1", playlist.playlistId)
        assertEquals("Mix", playlist.title)
        assertEquals("/api/playlists/u1", server.takeRequest().path)
    }

    @Test
    fun `unwraps the playlist key and accepts the name alias`() = runTest {
        enqueue(body = """{"playlist": {"playlist_id": "p1", "name": "Editorial"}}""")

        val playlist = repository.getPlaylist("p1")

        assertEquals("p1", playlist.playlistId)
        assertEquals("Editorial", playlist.title)
    }

    @Test
    fun `maps a 404 to NotFoundApiException`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        val thrown = runCatching { repository.getPlaylist("nope") }.exceptionOrNull()

        assertInstanceOf(NotFoundApiException::class.java, thrown)
        assertEquals(1, server.requestCount)
    }
}
