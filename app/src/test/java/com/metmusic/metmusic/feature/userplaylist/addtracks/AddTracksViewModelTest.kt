package com.metmusic.metmusic.feature.userplaylist.addtracks

import com.metmusic.metmusic.core.data.SearchRepository
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
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

/**
 * Tests JVM de [AddTracksViewModel]: debounce de 300 ms contra `/api/search`,
 * toggle de selección y snapshot de ids seleccionados.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AddTracksViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var viewModel: AddTracksViewModel

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val path = request.path.orEmpty()
                return when {
                    path.startsWith("/api/search") -> MockResponse()
                        .setResponseCode(200)
                        .setBody(SEARCH_BODY)
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
        viewModel = AddTracksViewModel(SearchRepository(api))
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `search debounces query`() = runTest {
        viewModel.onQueryChange("da")
        testScheduler.advanceTimeBy(200)
        viewModel.onQueryChange("daft")
        testScheduler.advanceTimeBy(200)

        assertEquals(0, server.requestCount)

        testScheduler.advanceTimeBy(101)
        testScheduler.runCurrent()

        val state = viewModel.state.first { !it.isLoading && it.results.isNotEmpty() }

        assertEquals(
            listOf("t-1", "t-2"),
            state.results.map { track -> track.trackId },
        )
        assertEquals(1, server.requestCount)
        assertEquals("daft", state.query)
    }

    @Test
    fun `toggle selection toggles`() {
        viewModel.toggleSelection("t-1")
        assertEquals(setOf("t-1"), viewModel.state.value.selected)

        viewModel.toggleSelection("t-2")
        assertEquals(setOf("t-1", "t-2"), viewModel.state.value.selected)

        viewModel.toggleSelection("t-1")
        assertEquals(setOf("t-2"), viewModel.state.value.selected)
    }

    @Test
    fun `selectedIds returns list`() {
        viewModel.toggleSelection("t-2")
        viewModel.toggleSelection("t-1")

        assertEquals(setOf("t-1", "t-2"), viewModel.selectedIds().toSet())
    }

    private companion object {
        val SEARCH_BODY = """
            {"tracks":[{"track_id":"t-1","title":"One More Time","artist":"Daft Punk"},
            {"track_id":"t-2","title":"Aerodynamic","artist":"Daft Punk"}],
            "total_results":2}
        """.trimIndent()
    }
}
