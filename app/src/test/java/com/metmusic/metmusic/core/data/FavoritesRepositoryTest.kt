package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeFavoritesDao
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import com.metmusic.metmusic.core.util.JsonParse
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class FavoritesRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var dao: FakeFavoritesDao
    private lateinit var repository: FavoritesRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        dao = FakeFavoritesDao()
        repository = FavoritesRepository(dao, UserRepository(api))
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    private fun trackJson(trackId: String, title: String): String =
        JsonParse.encode(Track(trackId = trackId, title = title).toJson())

    @Test
    fun `toggle adds when absent`() = runTest {
        enqueue()

        val state = repository.toggle(Track(trackId = "t1", title = "Tema"))

        assertTrue(state)
        assertTrue(repository.isFavorite("t1"))
        val request = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/user/favorites/t1", request.path)
    }

    @Test
    fun `toggle removes when present`() = runTest {
        dao.insert(
            FavoritesEntity(
                trackId = "t1",
                trackJson = trackJson("t1", "Tema"),
                addedAt = 1L,
            ),
        )
        enqueue()

        val state = repository.toggle(Track(trackId = "t1", title = "Tema"))

        assertFalse(state)
        assertFalse(repository.isFavorite("t1"))
        val request = server.takeRequest()
        assertEquals("DELETE", request.method)
        assertEquals("/api/user/favorites/t1", request.path)
    }

    @Test
    fun `toggle survives backend failure`() = runTest {
        enqueue(code = 500)

        val state = repository.toggle(Track(trackId = "t1", title = "Tema"))

        assertTrue(state)
        assertTrue(repository.isFavorite("t1"))
    }

    @Test
    fun `syncFromBackend replaces local with remote`() = runTest {
        dao.insert(
            FavoritesEntity(
                trackId = "old",
                trackJson = trackJson("old", "Vieja"),
                addedAt = 1L,
            ),
        )
        enqueue(body = """[{"track_id": "x", "title": "X"}, {"track_id": "y", "title": "Y"}]""")

        repository.syncFromBackend()

        val favorites = repository.getAll()
        assertEquals(2, favorites.size)
        assertEquals(setOf("x", "y"), favorites.map { it.trackId }.toSet())
        val request = server.takeRequest()
        assertEquals("GET", request.method)
        assertTrue(request.path.orEmpty().startsWith("/api/user/favorites?limit=200"))
    }

    @Test
    fun `getAll skips corrupted JSON`() = runTest {
        dao.insert(
            FavoritesEntity(
                trackId = "ok",
                trackJson = trackJson("ok", "Buena"),
                addedAt = 2L,
            ),
        )
        dao.insert(FavoritesEntity(trackId = "bad", trackJson = "not-json", addedAt = 1L))

        val favorites = repository.getAll()

        assertEquals(1, favorites.size)
        assertEquals("ok", favorites.first().trackId)
        assertEquals(0, server.requestCount)
    }
}
