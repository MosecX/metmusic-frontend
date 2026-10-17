package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
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

class UserRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var repository: UserRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        repository = UserRepository(api)
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `parses the playlists key`() = runTest {
        enqueue(body = """{"playlists": [{"id": "p1", "name": "Favoritas"}]}""")

        val playlists = repository.getPlaylists()

        assertEquals(1, playlists.size)
        assertEquals("p1", playlists[0].playlistId)
        assertEquals("Favoritas", playlists[0].name)
    }

    @Test
    fun `accepts a bare array of playlists`() = runTest {
        enqueue(body = """[{"id": "p2", "name": "Rock"}]""")

        val playlists = repository.getPlaylists()

        assertEquals(1, playlists.size)
        assertEquals("p2", playlists[0].playlistId)
    }

    @Test
    fun `unwraps the playlist key for a single playlist`() = runTest {
        enqueue(body = """{"playlist": {"id": "p3", "name": "Viaje"}}""")

        val playlist = repository.getPlaylist("p3")

        assertEquals("p3", playlist.playlistId)
        assertEquals("Viaje", playlist.name)
    }

    @Test
    fun `create sends the body and parses the response`() = runTest {
        enqueue(body = """{"id": "p4", "name": "Nueva"}""")

        val playlist = repository.createPlaylist("Nueva", "Una prueba", null)

        assertEquals("p4", playlist.playlistId)
        val request = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/user/playlists", request.path)
        val body = request.body.readUtf8()
        assertTrue(body.contains("\"name\":\"Nueva\""))
        assertTrue(body.contains("\"description\":\"Una prueba\""))
        assertFalse(body.contains("cover_url"))
    }

    @Test
    fun `update falls back when the response body is empty`() = runTest {
        enqueue(body = "")

        val playlist = repository.updatePlaylist("p9", "Renombrada", null, null)

        assertEquals("p9", playlist.playlistId)
        assertEquals("Renombrada", playlist.name)
    }

    @Test
    fun `history post sends the contract body`() = runTest {
        enqueue(body = "{}")

        repository.addHistory("t1", 42_000L, true)

        val request = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/user/history", request.path)
        val body = request.body.readUtf8()
        assertTrue(body.contains("\"track_id\":\"t1\""))
        assertTrue(body.contains("\"played_ms\":42000"))
        assertTrue(body.contains("\"completed\":true"))
    }

    @Test
    fun `history parses the history key`() = runTest {
        enqueue(body = """{"history": [{"track_id": "t9", "played_ms": 1000, "completed": true}]}""")

        val history = repository.getHistory()

        assertEquals(1, history.size)
        assertEquals("t9", history[0].trackId)
        assertEquals(1000, history[0].playedMs)
        assertTrue(history[0].completed)
    }

    @Test
    fun `favorites parses the favorites key`() = runTest {
        enqueue(body = """{"favorites": [{"track_id": "t1", "title": "Hit"}]}""")

        val favorites = repository.getFavorites()

        assertEquals(1, favorites.size)
        assertEquals("t1", favorites[0].trackId)
        assertEquals("Hit", favorites[0].title)
    }

    @Test
    fun `favorites accepts a bare array`() = runTest {
        enqueue(body = """[{"track_id": "t2", "title": "Otra"}]""")

        val favorites = repository.getFavorites()

        assertEquals(1, favorites.size)
        assertEquals("t2", favorites[0].trackId)
    }

    @Test
    fun `check favorites parses a list of ids`() = runTest {
        enqueue(body = """["t1", "t2"]""")

        val result = repository.checkFavorites(listOf("t1", "t2", "t3"))

        assertEquals(setOf("t1", "t2"), result)
        val path = server.takeRequest().path.orEmpty()
        assertTrue(path.startsWith("/api/user/favorites/check?ids=t1"))
    }

    @Test
    fun `check favorites parses the favorites map`() = runTest {
        enqueue(body = """{"favorites": ["t4"]}""")

        assertEquals(setOf("t4"), repository.checkFavorites(listOf("t4")))
    }

    @Test
    fun `check favorites parses a boolean map`() = runTest {
        enqueue(body = """{"t5": true, "t6": false}""")

        assertEquals(setOf("t5"), repository.checkFavorites(listOf("t5", "t6")))
    }

    @Test
    fun `check favorites with no ids skips the request`() = runTest {
        assertEquals(emptySet<String>(), repository.checkFavorites(emptyList()))

        assertEquals(0, server.requestCount)
    }

    @Test
    fun `add tracks with an empty list skips the request`() = runTest {
        repository.addTracks("p1", emptyList())

        assertEquals(0, server.requestCount)
    }

    @Test
    fun `reorder sends the ordered array`() = runTest {
        enqueue(body = "{}")

        repository.reorder("p1", listOf("b", "a"))

        assertEquals("""["b","a"]""", server.takeRequest().body.readUtf8())
    }

    @Test
    fun `delete playlist sends the delete verb`() = runTest {
        enqueue(body = "{}")

        repository.deletePlaylist("p7")

        val request = server.takeRequest()
        assertEquals("DELETE", request.method)
        assertEquals("/api/user/playlists/p7", request.path)
    }
}
