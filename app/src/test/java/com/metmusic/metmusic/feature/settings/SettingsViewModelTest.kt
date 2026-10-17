package com.metmusic.metmusic.feature.settings

import com.metmusic.metmusic.core.data.HealthRepository
import com.metmusic.metmusic.core.data.SettingsRepository
import com.metmusic.metmusic.core.data.fake.FakeSettingsStorage
import com.metmusic.metmusic.core.model.AudioQualityPreference
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
 * Tests JVM de [SettingsViewModel]: calidad persistida vía
 * [SettingsRepository], health con refresh/error y limpieza de caché del
 * servidor. El backend se mockea con MockWebServer por método/path.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var server: MockWebServer
    private lateinit var settingsRepository: SettingsRepository
    private lateinit var viewModel: SettingsViewModel

    @Volatile
    private var healthCode = 200

    @Volatile
    private var healthBody = HEALTH_BODY

    @Volatile
    private var cacheCode = 200

    @Volatile
    private var cacheBody = CACHE_BODY

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
                    method == "GET" && path == "/api/health" -> response(healthCode, healthBody)
                    method == "DELETE" && path == "/api/cache" -> response(cacheCode, cacheBody)
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
        settingsRepository = SettingsRepository(FakeSettingsStorage())
        val healthRepository = HealthRepository(api)
        viewModel = SettingsViewModel(settingsRepository, healthRepository)
    }

    @AfterEach
    fun tearDown() {
        Dispatchers.resetMain()
        server.shutdown()
    }

    @Test
    fun `initial quality comes from repository`() = runTest {
        awaitInitialLoad()

        assertEquals(AudioQualityPreference.BEST, viewModel.state.value.audioQuality)
    }

    @Test
    fun `setQuality persists to repository`() = runTest {
        awaitInitialLoad()

        viewModel.setQuality(AudioQualityPreference.LOW)

        val state = viewModel.state.first { it.audioQuality == AudioQualityPreference.LOW }
        assertEquals("Calidad actualizada", state.actionMessage)
        assertEquals(AudioQualityPreference.LOW, settingsRepository.settings.first().audioQuality)
    }

    @Test
    fun `refreshHealth populates state with health status`() = runTest {
        awaitInitialLoad()
        healthBody = HEALTH_BODY_ALT

        viewModel.refreshHealth()

        val state = viewModel.state.first { state ->
            state.healthServices.any { service -> service.id == "alt-catalog" }
        }
        assertEquals(2, state.healthServices.size)
        assertNull(state.healthError)
        assertEquals(2, recordedRequests.count { it == "GET" to "/api/health" })
    }

    @Test
    fun `refreshHealth error sets healthError`() = runTest {
        awaitInitialLoad()
        healthCode = 500
        healthBody = """{"detail":"boom"}"""

        viewModel.refreshHealth()

        val state = viewModel.state.first { it.healthError != null }
        assertEquals("boom", state.healthError)
        assertFalse(state.isLoadingHealth)
    }

    @Test
    fun `clearServerCache success sets actionMessage`() = runTest {
        awaitInitialLoad()

        viewModel.clearServerCache()

        val state = viewModel.state.first { it.actionMessage != null }
        assertEquals("Caché del servidor limpiada", state.actionMessage)
        assertFalse(state.isClearingCache)
        assertTrue(recordedRequests.contains("DELETE" to "/api/cache"))
    }

    @Test
    fun `clearServerCache failure sets actionMessage`() = runTest {
        awaitInitialLoad()
        cacheCode = 500
        cacheBody = """{"detail":"boom"}"""

        viewModel.clearServerCache()

        val state = viewModel.state.first { it.actionMessage != null }
        assertEquals("boom", state.actionMessage)
        assertFalse(state.isClearingCache)
    }

    /** Espera a que el refresh de health del init complete con éxito. */
    private suspend fun awaitInitialLoad() {
        viewModel.state.first { !it.isLoadingHealth && it.healthStatus != null }
    }

    private fun response(code: Int, body: String): MockResponse =
        MockResponse().setResponseCode(code).setBody(body)

    private companion object {
        val HEALTH_BODY = """
            {"ok":true,"status":"ok","version":"1.6.1","services":[
            {"id":"catalog","name":"Catálogo","ok":true,"latency_ms":42},
            {"id":"stream","name":"Stream","ok":true}]}
        """.trimIndent()

        val HEALTH_BODY_ALT = """
            {"ok":true,"status":"ok","services":[
            {"id":"alt-catalog","name":"Catálogo","ok":true,"latency_ms":15},
            {"id":"alt-stream","name":"Stream","ok":false}]}
        """.trimIndent()

        val CACHE_BODY = """{"deleted":1,"pattern":"*"}"""
    }
}
