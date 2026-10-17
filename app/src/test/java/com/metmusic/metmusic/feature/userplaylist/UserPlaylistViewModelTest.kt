package com.metmusic.metmusic.feature.userplaylist

import androidx.lifecycle.SavedStateHandle
import com.metmusic.metmusic.core.data.UserPlaylistsRepository
import com.metmusic.metmusic.core.data.UserRepository
import com.metmusic.metmusic.core.data.fake.FakeUserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import com.metmusic.metmusic.core.util.JsonParse
import java.util.Collections
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

/**
 * Tests JVM de [UserPlaylistViewModel]: carga cache-first con refresh
 * best-effort, remove optimista con rollback y reorder optimista con rollback.
 * El backend se mockea con MockWebServer ruteado por método + path.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class UserPlaylistViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var viewModel: UserPlaylistViewModel

    /** Método + path de cada request, para verificar las acciones. */
    private val requests: MutableList<Pair<String, String>> =
        Collections.synchronizedList(mutableListOf())

    @Volatile
    private var failRemove = false

    @Volatile
    private var failReorder = false

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val method = request.method.orEmpty()
                val path = request.path.orEmpty()
                requests += method to path
                return when {
                    method == "GET" && path == "/api/user/playlists" -> ok(PLAYLIST_LIST_BODY)
                    method == "GET" && path == "/api/user/playlists/pl-1" -> ok(PLAYLIST_BODY)
                    method == "DELETE" &&
                        path == "/api/user/playlists/pl-1/tracks/t-2" ->
                        if (failRemove) serverError() else ok("{}")
                    method == "PUT" && path == "/api/user/playlists/pl-1/reorder" ->
                        if (failReorder) serverError() else ok("{}")
                    else -> MockResponse().setResponseCode(404)
                }
            }
        }
        server.start()

        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)

        val dao = FakeUserPlaylistDao()
        runBlocking { dao.insert(cachedEntity()) }
        viewModel = UserPlaylistViewModel(
            userPlaylistsRepository = UserPlaylistsRepository(dao, UserRepository(api)),
            savedStateHandle = SavedStateHandle(mapOf("playlistId" to "pl-1")),
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `load reads cache and refreshes from backend`() = runTest {
        val state = viewModel.state.first { !it.isLoading && it.tracks.size == 3 }

        assertEquals("Roadtrip", state.playlist?.name)
        assertEquals("Para el auto", state.playlist?.description)
        assertEquals(
            listOf("t-1", "t-2", "t-3"),
            state.tracks.map { track -> track.trackId },
        )
        assertNull(state.error)
        assertTrue(requests.contains("GET" to "/api/user/playlists"))
    }

    @Test
    fun `removeTrack optimistically filters and calls backend`() = runTest {
        viewModel.state.first { !it.isLoading && it.tracks.size == 3 }
        val loadRequest = server.takeRequest()
        assertEquals("GET", loadRequest.method)
        assertEquals("/api/user/playlists", loadRequest.path)

        viewModel.removeTrack("t-2")

        val state = viewModel.state.first { current ->
            current.tracks.none { track -> track.trackId == "t-2" }
        }

        assertEquals(listOf("t-1", "t-3"), state.tracks.map { track -> track.trackId })
        assertNull(state.actionError)

        // El DELETE corre en el dispatcher de test: se espera desde IO para
        // que el scheduler pueda ejecutar la corrutina del ViewModel.
        val deleteRequest = withContext(Dispatchers.IO) {
            server.takeRequest(5, TimeUnit.SECONDS)
        }
        assertEquals("DELETE", deleteRequest?.method)
        assertEquals("/api/user/playlists/pl-1/tracks/t-2", deleteRequest?.path)

        // La acción del repo sigue con el refetch best-effort del cache.
        val refetchRequest = withContext(Dispatchers.IO) {
            server.takeRequest(5, TimeUnit.SECONDS)
        }
        assertEquals("GET", refetchRequest?.method)
        assertEquals("/api/user/playlists/pl-1", refetchRequest?.path)
    }

    @Test
    fun `removeTrack rolls back on failure`() = runTest {
        failRemove = true
        viewModel.state.first { !it.isLoading && it.tracks.size == 3 }

        viewModel.removeTrack("t-2")

        val state = viewModel.state.first { it.actionError != null }

        assertEquals(
            listOf("t-1", "t-2", "t-3"),
            state.tracks.map { track -> track.trackId },
        )
        assertEquals("No se pudo quitar la canción", state.actionError)
    }

    @Test
    fun `moveTrack reorders locally and calls backend`() = runTest {
        viewModel.state.first { !it.isLoading && it.tracks.size == 3 }

        viewModel.moveTrack(0, 2)

        val expected = listOf("t-2", "t-3", "t-1")
        val state = viewModel.state.first { current ->
            !current.isSavingOrder &&
                current.tracks.map { track -> track.trackId } == expected &&
                requests.contains("PUT" to "/api/user/playlists/pl-1/reorder")
        }

        assertEquals(expected, state.tracks.map { track -> track.trackId })
        assertNull(state.actionError)
    }

    @Test
    fun `moveTrack rolls back on failure`() = runTest {
        failReorder = true
        viewModel.state.first { !it.isLoading && it.tracks.size == 3 }

        viewModel.moveTrack(0, 2)

        val state = viewModel.state.first { it.actionError != null }

        assertEquals(
            listOf("t-1", "t-2", "t-3"),
            state.tracks.map { track -> track.trackId },
        )
        assertEquals("No se pudo guardar el orden", state.actionError)
        assertFalse(state.isSavingOrder)
    }

    /** Playlist cacheada con dos canciones: el refresh debe traer la tercera. */
    private fun cachedEntity(): UserPlaylistEntity {
        val tracks = listOf(
            Track(trackId = "t-1", title = "Uno", artist = "Coda"),
            Track(trackId = "t-2", title = "Dos", artist = "Coda"),
        )
        return UserPlaylistEntity(
            id = "pl-1",
            name = "Roadtrip",
            description = "Para el auto",
            trackCount = tracks.size,
            tracksJson = JsonParse.encode(tracks.map { track -> track.toJson() }),
            cachedAt = 0L,
        )
    }

    private fun ok(body: String): MockResponse =
        MockResponse().setResponseCode(200).setBody(body)

    private fun serverError(): MockResponse =
        MockResponse().setResponseCode(500).setBody("""{"detail":"boom"}""")

    private companion object {
        val TRACKS_JSON = """
            [
              {"track_id":"t-1","title":"Uno","artist":"Coda","duration_seconds":100},
              {"track_id":"t-2","title":"Dos","artist":"Coda","duration_seconds":120},
              {"track_id":"t-3","title":"Tres","artist":"Coda","duration_seconds":140}
            ]
        """.trimIndent()

        val PLAYLIST_LIST_BODY = """
            {"playlists":[{"id":"pl-1","name":"Roadtrip","description":"Para el auto",
            "track_count":3,"tracks":$TRACKS_JSON}]}
        """.trimIndent()

        val PLAYLIST_BODY = """
            {"id":"pl-1","name":"Roadtrip","description":"Para el auto",
            "track_count":3,"tracks":$TRACKS_JSON}
        """.trimIndent()
    }
}
