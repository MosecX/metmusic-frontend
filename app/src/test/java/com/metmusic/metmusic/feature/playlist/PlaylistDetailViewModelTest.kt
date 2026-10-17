package com.metmusic.metmusic.feature.playlist

import androidx.lifecycle.SavedStateHandle
import com.metmusic.metmusic.core.data.PlaylistRepository
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
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
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

/**
 * Tests JVM de [PlaylistDetailViewModel]: carga, error y retry contra un
 * MockWebServer ruteado por path.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class PlaylistDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var viewModel: PlaylistDetailViewModel

    @Volatile
    private var playlistCode = 200

    @Volatile
    private var playlistBody = PLAYLIST_BODY

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val path = request.path.orEmpty()
                return when {
                    path == "/api/playlists/pl-1" -> response(playlistCode, playlistBody)
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
        viewModel = PlaylistDetailViewModel(
            playlistRepository = PlaylistRepository(api),
            savedStateHandle = SavedStateHandle(mapOf("playlistId" to "pl-1")),
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `loads playlist and sets state`() = runTest {
        val state = viewModel.state.first { !it.isLoading && it.playlist != null }

        val playlist = state.playlist
        assertEquals("French Touch Classics", playlist?.title)
        assertEquals("MetMusic", playlist?.creator)
        assertEquals(2, playlist?.trackCount)
        assertEquals(2, playlist?.tracks?.size)
        assertNull(state.error)
    }

    @Test
    fun `error state on ApiException`() = runTest {
        playlistCode = 500
        playlistBody = """{"detail":"boom"}"""

        val state = viewModel.state.first { it.error != null }

        assertEquals("boom", state.error)
        assertEquals(false, state.isLoading)
    }

    @Test
    fun `retry reloads after error`() = runTest {
        playlistCode = 500
        playlistBody = """{"detail":"boom"}"""
        viewModel.state.first { it.error != null }

        playlistCode = 200
        playlistBody = PLAYLIST_BODY
        viewModel.retry()

        val state = viewModel.state.first { it.playlist != null }

        assertEquals("French Touch Classics", state.playlist?.title)
        assertNull(state.error)
    }

    private fun response(code: Int, body: String): MockResponse =
        MockResponse().setResponseCode(code).setBody(body)
}

private val PLAYLIST_BODY = """
    {"playlist":{"playlist_id":"pl-1","title":"French Touch Classics","creator":"MetMusic",
    "number_of_tracks":2,
    "tracks":[{"track_id":"t-1","title":"One More Time","duration_seconds":320},
    {"track_id":"t-2","title":"Aerodynamic","duration_seconds":212}]}}
""".trimIndent()
