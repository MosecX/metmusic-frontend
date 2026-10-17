package com.metmusic.metmusic.feature.album

import androidx.lifecycle.SavedStateHandle
import com.metmusic.metmusic.core.data.AlbumRepository
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
 * Tests JVM de [AlbumDetailViewModel]: carga, error y retry contra un
 * MockWebServer ruteado por path.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AlbumDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var viewModel: AlbumDetailViewModel

    @Volatile
    private var albumCode = 200

    @Volatile
    private var albumBody = ALBUM_BODY

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val path = request.path.orEmpty()
                return when {
                    path == "/api/albums/album-1" -> response(albumCode, albumBody)
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
        viewModel = AlbumDetailViewModel(
            albumRepository = AlbumRepository(api),
            savedStateHandle = SavedStateHandle(mapOf("albumId" to "album-1")),
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `loads album and sets state`() = runTest {
        val state = viewModel.state.first { !it.isLoading && it.album != null }

        val album = state.album
        assertEquals("Discovery", album?.title)
        assertEquals("Daft Punk", album?.artist)
        assertEquals("artist-1", album?.artistId)
        assertEquals(2, album?.tracks?.size)
        assertNull(state.error)
    }

    @Test
    fun `error state on ApiException`() = runTest {
        albumCode = 500
        albumBody = """{"detail":"boom"}"""

        val state = viewModel.state.first { it.error != null }

        assertEquals("boom", state.error)
        assertEquals(false, state.isLoading)
    }

    @Test
    fun `retry reloads after error`() = runTest {
        albumCode = 500
        albumBody = """{"detail":"boom"}"""
        viewModel.state.first { it.error != null }

        albumCode = 200
        albumBody = ALBUM_BODY
        viewModel.retry()

        val state = viewModel.state.first { it.album != null }

        assertEquals("Discovery", state.album?.title)
        assertNull(state.error)
    }

    private fun response(code: Int, body: String): MockResponse =
        MockResponse().setResponseCode(code).setBody(body)
}

private val ALBUM_BODY = """
    {"album":{"album_id":"album-1","title":"Discovery","artist":"Daft Punk",
    "artist_id":"artist-1","release_date":"2001-03-07","number_of_tracks":2,
    "tracks":[{"track_id":"t-1","title":"One More Time","duration_seconds":320},
    {"track_id":"t-2","title":"Aerodynamic","duration_seconds":212}]}}
""".trimIndent()
