package com.metmusic.metmusic.feature.mix

import com.metmusic.metmusic.core.data.MixFavoritesRepository
import com.metmusic.metmusic.core.data.RadioRepository
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity
import com.metmusic.metmusic.core.model.RadioMix
import com.metmusic.metmusic.core.model.RadioStation
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.ApiException
import com.metmusic.metmusic.core.network.NotFoundApiException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class MixViewModelTest {

    private lateinit var server: MockWebServer
    private lateinit var radioRepository: RadioRepository
    private val favoritesDao = FakeMixFavoritesDao()
    private val mixFavoritesRepository = MixFavoritesRepository(favoritesDao)

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().build())
            .build()
            .create(MetMusicApi::class.java)
        radioRepository = RadioRepository(api)
        Dispatchers.setMain(UnconfinedTestDispatcher())
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    private fun enqueueRadio(
        code: Int = 200,
        mixId: String = "mix-1",
        trackId: String = "seed",
        items: List<Track> = listOf(
            Track(trackId = "t1", title = "First", artist = "A", durationSeconds = 180),
            Track(trackId = "t2", title = "Second", artist = "B", durationSeconds = 240),
        ),
    ) {
        server.enqueue(
            MockResponse()
                .setResponseCode(code)
                .setBody(
                    """{"track_id":"$trackId","mix":{"id":"$mixId","title":"Mix $mixId"},"items":$items}""",
                ),
        )
    }

    @Test
    fun `loads station and sets state`() = runTest {
        enqueueRadio()

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        val state = observe(viewModel)

        assertTrue(state.isLoading)
        server.takeRequest() // espera la primera carga

        viewModel.retry()

        val final = observe(viewModel)
        assertNotNull(final.station)
        assertEquals(2, final.station!!.items.size)
        assertEquals("Mix mix-1", final.station!!.mix.title)
        assertEquals(listOf("t1", "t2"), final.station!!.items.map { it.trackId })
        assertFalse(final.isFavorite)
        assertFalse(final.isNotFound)
        assertNull(final.error)
    }

    @Test
    fun `404 sets notFound instead of error`() = runTest {
        server.enqueue(MockResponse().setResponseCode(404).setBody("{\"detail\":\"missing\"}"))

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        val state = observe(viewModel)
        assertFalse(state.isNotFound)

        viewModel.retry()

        val final = observe(viewModel)
        assertTrue(final.isNotFound)
        assertFalse(final.isLoading)
        assertNull(final.error)
        assertNull(final.station)
    }

    @Test
    fun `network error sets error`() = runTest {
        server.enqueue(MockResponse().setResponseCode(500).setBody("{\"detail\":\"boom\"}"))

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.retry()

        val final = observe(viewModel)
        assertFalse(final.isNotFound)
        assertFalse(final.isLoading)
        assertNotNull(final.error)
        assertNull(final.station)
    }

    @Test
    fun `toggleFavorite saves the mix and updates state`() = runTest {
        enqueueRadio()
        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))

        // carga inicial: no favorito
        val initial = observe(viewModel)
        assertFalse(initial.isFavorite)

        // toggle: repos devuelve true
        viewModel.toggleFavorite()
        val afterSave = observe(viewModel)
        assertTrue(afterSave.isTogglingFavorite)
        assertEquals(true, afterSave.isFavorite)

        // confirmamos que el repo reflecha el estado
        server.enqueue(MockResponse().setResponseCode(200).setBody("{\"exists\":true}"))
        assertEquals(true, mixFavoritesRepository.isFavorite("seed"))
    }

    @Test
    fun `toggleFavorite removes the mix when already saved`() = runTest {
        enqueueRadio()
        favoritesDao.insert(
            MixFavoritesEntity(
                trackId = "seed",
                mixId = "mix-1",
                title = "Mix",
            ),
        )
        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))

        viewModel.toggleFavorite()
        val afterRemove = observe(viewModel)

        assertFalse(afterRemove.isTogglingFavorite)
        assertFalse(afterRemove.isFavorite)
        assertEquals(false, mixFavoritesRepository.isFavorite("seed"))
    }

    @Test
    fun `actionError is dismissed after showing snackbar`() = runTest {
        enqueueRadio()
        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.toggleFavorite()
        val stateWithError = observe(viewModel)
        assertTrue(stateWithError.actionError != null)

        viewModel.dismissActionError()
        val afterDismiss = observe(viewModel)
        assertNull(afterDismiss.actionError)
    }

    @Test
    fun `tracks and metadata flow from a complete station payload`() = runTest {
        val items = listOf(
            Track(trackId = "t1", title = "A", artist = "A", durationSeconds = 180),
            Track(trackId = "t2", title = "B", artist = "B", durationSeconds = 240),
        )
        enqueueRadio(items = items)

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.retry()
        val final = observe(viewModel)

        assertNotNull(final.station)
        assertEquals("seed", final.station!!.trackId)
        assertEquals("Mix mix-1", final.station!!.mix.title)
        assertEquals("A", final.station!!.mix.subTitle)
        assertEquals("Descripción de la estación", final.station!!.mix.description)
        assertEquals("https://example.com/mix.jpg", final.station!!.mix.imageUrl)
        assertEquals(items, final.station!!.items)
    }

    @Test
    fun `title, subtitle and description are null-safe when missing`() = runTest {
        server.enqueue(
            MockResponse()
                .setResponseCode(200)
                .setBody("""{"track_id":"seed","mix":{"id":"m1"},"items":[]}"""),
        )

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.retry()
        val final = observe(viewModel)

        assertNotNull(final.station)
        assertEquals("", final.station!!.mix.title)
        assertNull(final.station!!.subTitle)
        assertNull(final.station!!.description)
        assertTrue(final.tracks.isEmpty())
    }

    @Test
    fun `toggleFavorite returns false when backend toggle removes the entry`() = runTest {
        enqueueRadio()
        favoritesDao.insert(
            MixFavoritesEntity(
                trackId = "seed",
                mixId = "mix-1",
                title = "Mix",
            ),
        )
        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))

        viewModel.toggleFavorite()
        val state = observe(viewModel)

        assertFalse(state.isFavorite)
        assertFalse(mixFavoritesRepository.isFavorite("seed"))
    }

    @Test
    fun `isNotFound is separate from error for a real 404 station`() = runTest {
        server.enqueue(MockResponse().setResponseCode(404).setBody("{\"detail\":\"missing\"}"))

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.retry()
        val final = observe(viewModel)

        assertTrue(final.isNotFound)
        assertFalse(final.isLoading)
        assertNull(final.error)
        assertNull(final.station)
    }

    @Test
    fun `network error keeps isNotFound false`() = runTest {
        server.enqueue(MockResponse().setResponseCode(500).setBody("{\"detail\":\"boom\"}"))

        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))
        viewModel.retry()
        val final = observe(viewModel)

        assertFalse(final.isNotFound)
        assertFalse(final.isLoading)
        assertNotNull(final.error)
    }

    @Test
    fun `load is idempotent when a station is already present`() = runTest {
        enqueueRadio()
        val viewModel = MixViewModel(radioRepository, mixFavoritesRepository, savedStateHandle("seed"))

        val before = observe(viewModel)
        viewModel.retry()
        val after = observe(viewModel)

        assertEquals(before, after)
    }

    private fun savedStateHandle(trackId: String) = object : SavedStateHandle {
        override fun getLiveData(key: String): kotlinx.coroutines.flow.MutableStateFlow<String?> {
            val flow = kotlinx.coroutines.flow.MutableStateFlow(trackId)
            return flow
        }

        override fun <T> getLiveData(key: String, default: T): kotlinx.coroutines.flow.MutableStateFlow<T?> {
            val flow = kotlinx.coroutines.flow.MutableStateFlow(default as T?)
            return flow
        }

        override fun get(key: String): Any? = throw NotImplementedError()

        override fun <T> get(key: String, default: T): T = default

        override fun set(key: String, value: Any?) {
            throw NotImplementedError()
        }

        override fun <T> getOrNull(key: String): T? = throw NotImplementedError()

        override fun <T> get(key: String, crossfooter: kotlin.reflect.Type?): T = throw NotImplementedError()

        override fun contains(key: String): Boolean = throw NotImplementedError()

        override fun getMap(key: String): kotlin.collections.Map<String, Any?> = throw NotImplementedError()

        override fun setMap(map: kotlin.collections.Map<String, Any?>) {
            throw NotImplementedError()
        }

        override fun keys(): kotlin.collections.Set<String> = throw NotImplementedError()
    }

    private fun observe(viewModel: MixViewModel): MixUiState {
        return kotlinx.coroutines.flow.first(viewModel.state)
    }
}
