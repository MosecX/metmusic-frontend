package com.metmusic.metmusic.feature.home

import com.metmusic.metmusic.core.data.ExploreRepository
import com.metmusic.metmusic.core.data.HistoryRepository
import com.metmusic.metmusic.core.data.UserRepository
import com.metmusic.metmusic.core.data.fake.FakeHistoryDao
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import java.util.Collections
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
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
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

/**
 * Tests JVM de [HomeViewModel] con MockWebServer: las cuatro fuentes (explore
 * home, novedades, charts e historial local) se resuelven en paralelo y cada
 * una por separado.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class HomeViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var dao: FakeHistoryDao
    private lateinit var viewModel: HomeViewModel

    private val requestedPaths: MutableList<String> =
        Collections.synchronizedList(mutableListOf())

    @Volatile
    private var failExploreHome = false

    @Volatile
    private var failNewReleases = false

    @Volatile
    private var failCharts = false

    @BeforeEach
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        server = MockWebServer()
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse {
                val path = request.path.orEmpty()
                requestedPaths += path
                return when {
                    path.startsWith("/api/explore/home") -> when {
                        failExploreHome -> failureResponse()
                        path.contains("mood=chill") -> ok(EXPLORE_HOME_CHILL_BODY)
                        else -> ok(EXPLORE_HOME_BODY)
                    }
                    path.startsWith("/api/explore/new_releases") ->
                        if (failNewReleases) failureResponse() else ok(NEW_RELEASES_BODY)
                    path.startsWith("/api/explore/charts") ->
                        if (failCharts) failureResponse() else ok(CHARTS_BODY)
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
        dao = FakeHistoryDao()
        val exploreRepository = ExploreRepository(api)
        val historyRepository = HistoryRepository(dao, UserRepository(api))
        viewModel = HomeViewModel(exploreRepository, historyRepository)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `loads explore new releases charts and recent in parallel`() = runTest {
        seedHistory()

        val state = viewModel.state.first { !it.isLoading }

        assertEquals(1, state.explore.sections.size)
        assertEquals(2, state.newReleases.size)
        assertEquals(1, state.charts.size)
        assertEquals(1, state.recent.size)
        assertNull(state.error)
        assertEquals(3, requestedPaths.size)
        assertTrue(requestedPaths.any { it.startsWith("/api/explore/home") })
        assertTrue(requestedPaths.any { it.startsWith("/api/explore/new_releases") })
        assertTrue(requestedPaths.any { it.startsWith("/api/explore/charts") })
    }

    @Test
    fun `offline fallback when explore fails but recent exists`() = runTest {
        seedHistory()
        failExploreHome = true

        val state = viewModel.state.first { !it.isLoading }

        assertTrue(state.offline)
        assertEquals(1, state.recent.size)
        assertEquals(2, state.newReleases.size)
        assertNull(state.error)
    }

    @Test
    fun `error state when all sources fail`() = runTest {
        failExploreHome = true
        failNewReleases = true
        failCharts = true

        val state = viewModel.state.first { !it.isLoading }

        assertTrue(state.isEmpty)
        assertNotNull(state.error)
        assertEquals("boom", state.error)
    }

    @Test
    fun `mood selection reloads explore only`() = runTest {
        seedHistory()
        var state = viewModel.state.first { !it.isLoading }
        val requestsAfterInitialLoad = requestedPaths.size
        val charts = state.charts
        val recent = state.recent

        viewModel.onMoodSelected("chill")
        state = viewModel.state.first { it.hasChillTrack() }

        assertEquals("chill", state.selectedMood)
        assertEquals(requestsAfterInitialLoad + 1, requestedPaths.size)
        assertEquals(
            1,
            requestedPaths.count { it.startsWith("/api/explore/home") && it.contains("mood=chill") },
        )
        assertEquals(charts, state.charts)
        assertEquals(recent, state.recent)
        assertFalse(state.isLoading)
    }

    @Test
    fun `refresh reloads all sources and preserves selected mood`() = runTest {
        seedHistory()
        viewModel.state.first { !it.isLoading }
        viewModel.onMoodSelected("chill")
        viewModel.state.first { it.hasChillTrack() }
        val requestsBeforeRefresh = requestedPaths.size

        viewModel.refresh()
        val refreshing = viewModel.state.first { it.isRefreshing }
        assertTrue(refreshing.isRefreshing)

        val state = viewModel.state.first { !it.isRefreshing && !it.isLoading }

        assertEquals("chill", state.selectedMood)
        assertFalse(state.isRefreshing)
        assertEquals(requestsBeforeRefresh + 3, requestedPaths.size)
    }

    @Test
    fun `mood selection with same mood is a no-op`() = runTest {
        seedHistory()
        viewModel.state.first { !it.isLoading }
        viewModel.onMoodSelected("chill")
        viewModel.state.first { it.hasChillTrack() }
        val requestsAfterChill = requestedPaths.size

        viewModel.onMoodSelected("chill")
        advanceUntilIdle()

        assertEquals(requestsAfterChill, requestedPaths.size)
        assertEquals("chill", viewModel.state.value.selectedMood)
    }

    /** `true` cuando llegó el contenido de explore del mood chill. */
    private fun HomeUiState.hasChillTrack(): Boolean =
        explore.sections.any { section -> section.tracks.any { it.trackId == "chill-1" } }

    private suspend fun seedHistory() {
        dao.insert(
            HistoryEntity(
                trackId = "h-1",
                playedAt = 1_000L,
                playedMs = 120_000L,
                completed = true,
                trackJson = """{"track_id":"h-1","title":"Vieja","artist":"Coda"}""",
            ),
        )
    }

    private fun ok(body: String): MockResponse =
        MockResponse().setResponseCode(200).setBody(body)

    /** 500 con detalle: el parseo lo convierte en `ServerApiException("boom")`. */
    private fun failureResponse(): MockResponse =
        MockResponse().setResponseCode(500).setBody("""{"detail":"boom"}""")

    private companion object {
        val EXPLORE_HOME_BODY = """
            {"sections":[{"id":"explore_tracks","title":"Para vos","type":"tracks",
            "items":[{"track_id":"sec-1","title":"Section Track","artist":"Coda"}]}]}
        """.trimIndent()

        val EXPLORE_HOME_CHILL_BODY = """
            {"sections":[{"id":"explore_tracks","title":"Chill","type":"tracks",
            "items":[{"track_id":"chill-1","title":"Chill Track","artist":"Coda"}]}]}
        """.trimIndent()

        val NEW_RELEASES_BODY = """
            {"albums":[
            {"album_id":"al-1","title":"Nuevo","artist":"Coda"},
            {"album_id":"al-2","title":"Otro","artist":"Coda"}]}
        """.trimIndent()

        val CHARTS_BODY = """
            {"charts":[
            {"track_id":"ch-1","title":"Hit","artist":"Coda","duration_seconds":180}]}
        """.trimIndent()
    }
}
