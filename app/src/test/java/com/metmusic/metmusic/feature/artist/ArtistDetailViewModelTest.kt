package com.metmusic.metmusic.feature.artist

import androidx.lifecycle.SavedStateHandle
import com.metmusic.metmusic.core.data.ArtistRepository
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
 * Tests JVM de [ArtistDetailViewModel]: carga, error y retry contra un
 * MockWebServer ruteado por path.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ArtistDetailViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var viewModel: ArtistDetailViewModel

    @Volatile
    private var artistCode = 200

    @Volatile
    private var artistBody = ARTIST_BODY

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val path = request.path.orEmpty()
                return when {
                    path == "/api/artists/artist-1" -> response(artistCode, artistBody)
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
        viewModel = ArtistDetailViewModel(
            artistRepository = ArtistRepository(api),
            savedStateHandle = SavedStateHandle(mapOf("artistId" to "artist-1")),
        )
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `loads artist and sets state`() = runTest {
        val state = viewModel.state.first { !it.isLoading && it.artist != null }

        val artist = state.artist
        assertEquals("Daft Punk", artist?.name)
        assertEquals("French duo", artist?.bio)
        assertEquals(1, artist?.topTracks?.size)
        assertEquals(1, artist?.albums?.size)
        assertNull(state.error)
    }

    @Test
    fun `error state on ApiException`() = runTest {
        artistCode = 500
        artistBody = """{"detail":"boom"}"""

        val state = viewModel.state.first { it.error != null }

        assertEquals("boom", state.error)
        assertEquals(false, state.isLoading)
    }

    @Test
    fun `retry reloads after error`() = runTest {
        artistCode = 500
        artistBody = """{"detail":"boom"}"""
        viewModel.state.first { it.error != null }

        artistCode = 200
        artistBody = ARTIST_BODY
        viewModel.retry()

        val state = viewModel.state.first { it.artist != null }

        assertEquals("Daft Punk", state.artist?.name)
        assertNull(state.error)
    }

    private fun response(code: Int, body: String): MockResponse =
        MockResponse().setResponseCode(code).setBody(body)
}

private val ARTIST_BODY = """
    {"artist":{"artist_id":"artist-1","name":"Daft Punk","bio":"French duo",
    "tracks":[{"track_id":"t-1","title":"One More Time","duration_seconds":320}],
    "albums":[{"album_id":"a-1","title":"Discovery"}]}}
""".trimIndent()
