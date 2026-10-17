package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeUserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import com.metmusic.metmusic.core.util.JsonParse
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class UserPlaylistsRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var dao: FakeUserPlaylistDao
    private lateinit var repository: UserPlaylistsRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        dao = FakeUserPlaylistDao()
        repository = UserPlaylistsRepository(dao, UserRepository(api))
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    private fun cachedEntity(id: String, name: String, tracks: List<Track> = emptyList()) =
        UserPlaylistEntity(
            id = id,
            name = name,
            tracksJson = JsonParse.encode(tracks.map { it.toJson() }),
            cachedAt = 0L,
        )

    @Test
    fun `create calls the backend and inserts the new playlist in cache`() = runTest {
        enqueue(body = """{"id": "p1", "name": "Nueva"}""")

        val created = repository.create("Nueva", null, null)

        assertEquals("p1", created.playlistId)
        assertEquals("p1", dao.getById("p1")?.id)
        val request = server.takeRequest()
        assertEquals("POST", request.method)
        assertEquals("/api/user/playlists", request.path)
    }

    @Test
    fun `delete calls the backend and removes from cache`() = runTest {
        dao.insert(cachedEntity("p1", "Vieja"))
        enqueue()

        repository.delete("p1")

        assertEquals(null, dao.getById("p1"))
        val request = server.takeRequest()
        assertEquals("DELETE", request.method)
        assertEquals("/api/user/playlists/p1", request.path)
    }

    @Test
    fun `refresh replaces local cache with remote list`() = runTest {
        dao.insert(cachedEntity("old", "Vieja"))
        enqueue(body = """[{"id": "a", "name": "A"}, {"id": "b", "name": "B"}]""")

        repository.refresh()

        assertEquals(setOf("a", "b"), repository.getAll().map { it.playlistId }.toSet())
        val request = server.takeRequest()
        assertEquals("GET", request.method)
        assertEquals("/api/user/playlists", request.path)
    }

    @Test
    fun `refresh propagates ApiException when backend fails`() = runTest {
        dao.insert(cachedEntity("old", "Vieja"))
        enqueue(code = 500)
        enqueue(code = 500)

        val result = runCatching { repository.refresh() }

        assertTrue(result.exceptionOrNull() is ApiException)
        assertEquals(2, server.requestCount)
        assertEquals("old", repository.getAll().single().playlistId)
    }

    @Test
    fun `rename updates local cache after backend succeeds`() = runTest {
        dao.insert(cachedEntity("p1", "Vieja"))
        enqueue(body = """{"id": "p1", "name": "Renombrada"}""")

        val updated = repository.rename("p1", "Renombrada")

        assertEquals("Renombrada", updated.name)
        assertEquals("Renombrada", dao.getById("p1")?.name)
        val request = server.takeRequest()
        assertEquals("PUT", request.method)
        assertEquals("/api/user/playlists/p1", request.path)
    }

    @Test
    fun `addTracks triggers a refetch and updates local cache`() = runTest {
        dao.insert(cachedEntity("p1", "P1"))
        enqueue()
        enqueue(
            body = """{"id": "p1", "name": "P1", "tracks": [{"track_id": "t1", "title": "Tema"}]}""",
        )

        repository.addTracks("p1", listOf("t1"))

        val cached = repository.getAll().single()
        assertEquals(listOf("t1"), cached.tracks.map { it.trackId })
        val add = server.takeRequest()
        assertEquals("POST", add.method)
        assertEquals("/api/user/playlists/p1/tracks", add.path)
        val refetch = server.takeRequest()
        assertEquals("GET", refetch.method)
        assertEquals("/api/user/playlists/p1", refetch.path)
    }

    @Test
    fun `reorder triggers a refetch and updates local cache`() = runTest {
        dao.insert(
            cachedEntity(
                "p1",
                "P1",
                listOf(Track(trackId = "t1", title = "Uno"), Track(trackId = "t2", title = "Dos")),
            ),
        )
        enqueue()
        enqueue(
            body = """{"id": "p1", "name": "P1", "tracks": [
                {"track_id": "t2", "title": "Dos"},
                {"track_id": "t1", "title": "Uno"}
            ]}""",
        )

        repository.reorder("p1", listOf("t2", "t1"))

        val cached = repository.getAll().single()
        assertEquals(listOf("t2", "t1"), cached.tracks.map { it.trackId })
        val reorder = server.takeRequest()
        assertEquals("PUT", reorder.method)
        assertEquals("/api/user/playlists/p1/reorder", reorder.path)
        val refetch = server.takeRequest()
        assertEquals("GET", refetch.method)
        assertEquals("/api/user/playlists/p1", refetch.path)
    }
}
