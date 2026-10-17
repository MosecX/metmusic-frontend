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
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class ArtistRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: ArtistRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = ArtistRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a plain artist payload with the id alias`() = runTest {
        enqueue(body = """{"id": "a1", "name": "Banda"}""")

        val artist = repository.getArtist("a1")

        assertEquals("a1", artist.artistId)
        assertEquals("Banda", artist.name)
        assertEquals("/api/artists/a1", server.takeRequest().path)
    }

    @Test
    fun `unwraps the artist key`() = runTest {
        enqueue(body = """{"artist": {"id": "a2", "name": "Otra Banda"}}""")

        val artist = repository.getArtist("a2")

        assertEquals("a2", artist.artistId)
        assertEquals("Otra Banda", artist.name)
    }

    @Test
    fun `fails with ApiException when the 5xx persists`() = runTest {
        enqueue(code = 500, body = "{}")
        enqueue(code = 500, body = "{}")

        val thrown = runCatching { repository.getArtist("a1") }.exceptionOrNull()

        assertInstanceOf(ApiException::class.java, thrown)
        assertEquals(2, server.requestCount)
    }
}
