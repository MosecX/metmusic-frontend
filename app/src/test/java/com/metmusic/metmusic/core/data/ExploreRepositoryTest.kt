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

class ExploreRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: ExploreRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = ExploreRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses a home payload with explicit sections`() = runTest {
        enqueue(
            body = """{"sections": [{"title": "Nuevos", "type": "albums", "items": [{"album_id": "al1", "title": "Uno"}]}]}""",
        )

        val home = repository.getHome(null)

        assertEquals(1, home.sections.size)
        assertEquals("al1", home.sections[0].albums[0].albumId)
    }

    @Test
    fun `parses a home payload of bare section lists`() = runTest {
        enqueue(body = """{"new_releases": [{"album_id": "al2", "title": "Dos"}]}""")

        val home = repository.getHome("chill")

        assertEquals(1, home.sections.size)
        assertEquals("al2", home.sections[0].albums[0].albumId)
        assertEquals("/api/explore/home?mood=chill", server.takeRequest().path)
    }

    @Test
    fun `returns an empty home when the body is not parseable`() = runTest {
        enqueue(body = "")

        assertTrue(repository.getHome(null).isEmpty)
    }

    @Test
    fun `new releases parse a map payload`() = runTest {
        enqueue(body = """{"albums": [{"album_id": "al3", "title": "Tres"}]}""")

        val albums = repository.getNewReleases()

        assertEquals(1, albums.size)
        assertEquals("al3", albums[0].albumId)
    }

    @Test
    fun `new releases accept a bare array`() = runTest {
        enqueue(body = """[{"album_id": "al4", "title": "Cuatro"}]""")

        val albums = repository.getNewReleases(limit = 5, offset = 10)

        assertEquals(1, albums.size)
        assertEquals("al4", albums[0].albumId)
        assertEquals("/api/explore/new_releases?limit=5&offset=10", server.takeRequest().path)
    }

    @Test
    fun `charts parse the charts key`() = runTest {
        enqueue(body = """{"charts": [{"track_id": "t1", "title": "Hit"}]}""")

        val tracks = repository.getCharts()

        assertEquals(1, tracks.size)
        assertEquals("t1", tracks[0].trackId)
        assertEquals("/api/explore/charts?limit=20", server.takeRequest().path)
    }

    @Test
    fun `moods send the mood and parse a bare array`() = runTest {
        enqueue(body = """[{"track_id": "t2", "title": "Moody"}]""")

        val tracks = repository.getMood("chill")

        assertEquals(1, tracks.size)
        assertEquals("t2", tracks[0].trackId)
        assertEquals("/api/explore/moods?mood=chill&limit=30", server.takeRequest().path)
    }

    @Test
    fun `fails with ApiException when the 5xx persists`() = runTest {
        enqueue(code = 500, body = "{}")
        enqueue(code = 500, body = "{}")

        val thrown = runCatching { repository.getCharts() }.exceptionOrNull()

        assertInstanceOf(ApiException::class.java, thrown)
        assertEquals(2, server.requestCount)
    }
}
