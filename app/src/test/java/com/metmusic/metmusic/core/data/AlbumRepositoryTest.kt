package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.ApiException
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

class AlbumRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: AlbumRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = AlbumRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain album payload`() = runTest {
        enqueue(body = """{"album_id": "al1", "title": "Uno", "artist": "Banda"}""")

        val album = repository.getAlbum("al1")

        assertEquals("al1", album.albumId)
        assertEquals("Uno", album.title)
        assertEquals("Banda", album.artist)
        assertEquals("/api/albums/al1", server.takeRequest().path)
    }

    @Test
    fun `unwraps the album key and accepts the images alias`() = runTest {
        enqueue(body = """{"album": {"id": "al2", "title": "Dos", "images": [{"url": "u.jpg"}]}}""")

        val album = repository.getAlbum("al2")

        assertEquals("al2", album.albumId)
        assertEquals("u.jpg", album.thumbnails[0].url)
    }

    @Test
    fun `maps a 404 to NotFoundApiException`() = runTest {
        enqueue(code = 404, body = """{"detail": "missing"}""")

        val thrown = runCatching { repository.getAlbum("nope") }.exceptionOrNull()

        assertInstanceOf(NotFoundApiException::class.java, thrown)
        assertEquals(1, server.requestCount)
    }

    @Test
    fun `retries a 5xx once and returns the next success`() = runTest {
        enqueue(code = 503, body = """{"detail": "down"}""")
        enqueue(body = """{"album_id": "al3", "title": "Tres"}""")

        val album = repository.getAlbum("al3")

        assertEquals("al3", album.albumId)
        assertEquals(2, server.requestCount)
    }

    @Test
    fun `fails with ApiException when the 5xx persists`() = runTest {
        enqueue(code = 500, body = "{}")
        enqueue(code = 500, body = "{}")

        val thrown = runCatching { repository.getAlbum("al1") }.exceptionOrNull()

        assertInstanceOf(ApiException::class.java, thrown)
        assertEquals(2, server.requestCount)
    }
}
