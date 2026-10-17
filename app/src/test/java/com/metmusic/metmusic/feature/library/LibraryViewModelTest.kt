package com.metmusic.metmusic.feature.library

import com.metmusic.metmusic.core.data.FavoritesRepository
import com.metmusic.metmusic.core.data.HistoryRepository
import com.metmusic.metmusic.core.data.MixFavoritesRepository
import com.metmusic.metmusic.core.data.UserPlaylistsRepository
import com.metmusic.metmusic.core.data.UserRepository
import com.metmusic.metmusic.core.data.fake.FakeFavoritesDao
import com.metmusic.metmusic.core.data.fake.FakeHistoryDao
import com.metmusic.metmusic.core.data.fake.FakeMixFavoritesDao
import com.metmusic.metmusic.core.data.fake.FakeUserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import java.util.Collections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
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
 * Tests JVM de [LibraryViewModel]: la carga lee las cuatro listas locales sin
 * tocar red y cada acción CRUD actualiza el estado en memoria. El backend se
 * mockea con MockWebServer para verificar método y path de cada acción.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class LibraryViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var playlistsDao: FakeUserPlaylistDao
    private lateinit var favoritesDao: FakeFavoritesDao
    private lateinit var mixesDao: FakeMixFavoritesDao
    private lateinit var historyDao: FakeHistoryDao
    private lateinit var viewModel: LibraryViewModel

    private val recordedRequests: MutableList<Pair<String, String>> =
        Collections.synchronizedList(mutableListOf())

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val method = request.method.orEmpty()
                val path = request.path.orEmpty()
                recordedRequests += method to path
                return when {
                    method == "POST" && path == "/api/user/playlists" -> ok(CREATE_BODY)
                    method == "PUT" && path == "/api/user/playlists/p-1" -> ok(RENAME_BODY)
                    method == "DELETE" && path == "/api/user/playlists/p-1" -> ok("{}")
                    method == "DELETE" && path == "/api/user/favorites/t-1" -> ok("{}")
                    method == "DELETE" && path == "/api/user/history" -> ok("{}")
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
        playlistsDao = FakeUserPlaylistDao()
        favoritesDao = FakeFavoritesDao()
        mixesDao = FakeMixFavoritesDao()
        historyDao = FakeHistoryDao()
        val userRepository = UserRepository(api)
        viewModel = LibraryViewModel(
            userPlaylistsRepository = UserPlaylistsRepository(playlistsDao, userRepository),
            favoritesRepository = FavoritesRepository(favoritesDao, userRepository),
            mixFavoritesRepository = MixFavoritesRepository(mixesDao),
            historyRepository = HistoryRepository(historyDao, userRepository),
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `load reads the four lists from local storage in parallel`() = runTest {
        playlistsDao.insert(playlistEntity("p-1", "Roadtrip"))
        favoritesDao.insert(favoriteEntity("t-1"))
        mixesDao.insert(mixEntity("t-2"))
        historyDao.insert(historyEntity("t-3"))

        val state = viewModel.state.first { !it.isLoading }

        assertEquals(1, state.playlists.size)
        assertEquals(1, state.favorites.size)
        assertEquals(1, state.mixes.size)
        assertEquals(1, state.history.size)
        assertNull(state.error)
        assertEquals(0, server.requestCount)
    }

    @Test
    fun `create playlist calls backend and prepends to list`() = runTest {
        playlistsDao.insert(playlistEntity("p-1", "Vieja"))
        viewModel.state.first { !it.isLoading && it.playlists.size == 1 }

        viewModel.createPlaylist("Nueva", "  ", " https://cover.example/x.png ")

        val state = viewModel.state.first { it.playlists.any { playlist -> playlist.playlistId == "p-new" } }

        assertEquals(listOf("p-new", "p-1"), state.playlists.map { it.playlistId })
        assertEquals("p-new", playlistsDao.getById("p-new")?.id)
        assertNull(playlistsDao.getById("p-new")?.description)
        assertTrue(recordedRequests.contains("POST" to "/api/user/playlists"))
    }

    @Test
    fun `rename playlist calls backend and replaces item in list`() = runTest {
        playlistsDao.insert(playlistEntity("p-1", "Vieja"))
        viewModel.state.first { !it.isLoading && it.playlists.size == 1 }

        viewModel.renamePlaylist("p-1", "  Renombrada  ")

        val state = viewModel.state.first { it.playlists.any { playlist -> playlist.name == "Renombrada" } }

        assertEquals(1, state.playlists.size)
        assertEquals("p-1", state.playlists.single().playlistId)
        assertEquals("Renombrada", playlistsDao.getById("p-1")?.name)
        assertTrue(recordedRequests.contains("PUT" to "/api/user/playlists/p-1"))
    }

    @Test
    fun `delete playlist calls backend and removes item from list`() = runTest {
        playlistsDao.insert(playlistEntity("p-1", "Vieja"))
        viewModel.state.first { !it.isLoading && it.playlists.size == 1 }

        viewModel.deletePlaylist("p-1")

        val state = viewModel.state.first { it.playlists.isEmpty() }

        assertTrue(state.playlists.isEmpty())
        assertNull(playlistsDao.getById("p-1"))
        assertTrue(recordedRequests.contains("DELETE" to "/api/user/playlists/p-1"))
    }

    @Test
    fun `remove favorite updates local state and cache`() = runTest {
        favoritesDao.insert(favoriteEntity("t-1"))
        viewModel.state.first { !it.isLoading && it.favorites.size == 1 }

        viewModel.removeFavorite("t-1")

        val state = viewModel.state.first { it.favorites.isEmpty() }

        assertTrue(state.favorites.isEmpty())
        assertFalse(favoritesDao.exists("t-1"))
        assertTrue(recordedRequests.contains("DELETE" to "/api/user/favorites/t-1"))
    }

    @Test
    fun `clear history clears local state and calls backend`() = runTest {
        historyDao.insert(historyEntity("t-3"))
        viewModel.state.first { !it.isLoading && it.history.size == 1 }

        viewModel.clearHistory()

        val state = viewModel.state.first { it.history.isEmpty() }

        assertTrue(state.history.isEmpty())
        assertEquals(0, historyDao.count())
        assertTrue(recordedRequests.contains("DELETE" to "/api/user/history"))
    }

    private fun playlistEntity(id: String, name: String) = UserPlaylistEntity(
        id = id,
        name = name,
        tracksJson = "[]",
        cachedAt = 0L,
    )

    private fun favoriteEntity(trackId: String) = FavoritesEntity(
        trackId = trackId,
        trackJson = """{"track_id":"$trackId","title":"Vieja","artist":"Coda"}""",
        addedAt = 1L,
    )

    private fun mixEntity(trackId: String) = MixFavoritesEntity(
        trackId = trackId,
        mixId = "mix-$trackId",
        title = "Mix de Coda",
        subTitle = "Coda",
        addedAt = 1L,
    )

    private fun historyEntity(trackId: String) = HistoryEntity(
        trackId = trackId,
        playedAt = 1_000L,
        playedMs = 120_000L,
        completed = true,
        trackJson = """{"track_id":"$trackId","title":"Vieja","artist":"Coda"}""",
    )

    private fun ok(body: String): MockResponse =
        MockResponse().setResponseCode(200).setBody(body)

    private companion object {
        val CREATE_BODY = """{"id":"p-new","name":"Nueva","track_count":0}"""
        val RENAME_BODY = """{"id":"p-1","name":"Renombrada","track_count":1}"""
    }
}
