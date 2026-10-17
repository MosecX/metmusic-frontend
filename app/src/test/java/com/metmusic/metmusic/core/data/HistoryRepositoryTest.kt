package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.fake.FakeHistoryDao
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import com.metmusic.metmusic.core.model.Track
import com.metmusic.metmusic.core.network.MetMusicApi
import com.metmusic.metmusic.core.network.RetryInterceptor
import kotlinx.coroutines.test.runTest
import okhttp3.OkHttpClient
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import retrofit2.Retrofit

class HistoryRepositoryTest {

    private lateinit var server: MockWebServer
    private lateinit var dao: FakeHistoryDao
    private lateinit var repository: HistoryRepository

    @BeforeEach
    fun setUp() {
        server = MockWebServer()
        server.start()
        val api = Retrofit.Builder()
            .baseUrl(server.url("/"))
            .client(OkHttpClient.Builder().addInterceptor(RetryInterceptor()).build())
            .build()
            .create(MetMusicApi::class.java)
        dao = FakeHistoryDao()
        repository = HistoryRepository(dao, UserRepository(api))
    }

    @AfterEach
    fun tearDown() {
        server.shutdown()
    }

    private fun enqueue(code: Int = 200, body: String = "{}") {
        server.enqueue(MockResponse().setResponseCode(code).setBody(body))
    }

    @Test
    fun `record persists entry and trims to 500`() = runTest {
        repeat(504) { index ->
            dao.insert(
                HistoryEntity(
                    trackId = "seed-$index",
                    playedAt = 1_000L + index,
                    playedMs = 100L,
                    completed = false,
                ),
            )
        }
        enqueue()

        repository.record("newest", 5_000L, true, null)

        val entries = repository.getAll(600)
        assertEquals(500, entries.size)
        assertEquals("newest", entries.first().trackId)
        assertEquals(0, entries.count { it.trackId == "seed-4" })
        assertEquals(1, entries.count { it.trackId == "seed-5" })
        assertEquals(1, server.requestCount)
    }

    @Test
    fun `recentDistinct returns one per trackId`() = runTest {
        dao.insert(HistoryEntity(trackId = "a", playedAt = 100L, playedMs = 10L, completed = false))
        dao.insert(HistoryEntity(trackId = "b", playedAt = 200L, playedMs = 10L, completed = false))
        dao.insert(HistoryEntity(trackId = "a", playedAt = 300L, playedMs = 10L, completed = false))
        dao.insert(HistoryEntity(trackId = "b", playedAt = 400L, playedMs = 10L, completed = false))

        val distinct = repository.recentDistinct(limit = 2)

        assertEquals(2, distinct.size)
        assertEquals(listOf("b", "a"), distinct.map { it.trackId })
        assertEquals(listOf(400L, 300L), distinct.map { it.playedAt })
        assertEquals(0, server.requestCount)
    }

    @Test
    fun `syncFromBackend merges without duplicating`() = runTest {
        dao.insert(
            HistoryEntity(
                trackId = "a",
                playedAt = 1_700_000_000_000L,
                playedMs = 1_000L,
                completed = true,
            ),
        )
        enqueue(
            body = """[
                {"track_id": "a", "played_at": 1700000000000, "played_ms": 1000, "completed": true},
                {"track_id": "b", "played_at": 1700000000001, "played_ms": 2000, "completed": false},
                {"track_id": "c", "played_at": 1700000000002, "played_ms": 3000, "completed": true}
            ]""",
        )

        repository.syncFromBackend()

        val entries = repository.getAll(10)
        assertEquals(3, entries.size)
        assertEquals(listOf("c", "b", "a"), entries.map { it.trackId })
        assertEquals(1, entries.count { it.trackId == "a" })
    }

    @Test
    fun `clear wipes local`() = runTest {
        dao.insert(HistoryEntity(trackId = "a", playedAt = 1L, playedMs = 1L, completed = false))
        enqueue()

        repository.clear()

        assertEquals(0, dao.count())
        val request = server.takeRequest()
        assertEquals("DELETE", request.method)
        assertEquals("/api/user/history", request.path)
    }

    @Test
    fun `record survives backend failure`() = runTest {
        enqueue(code = 500)
        val track = Track(trackId = "t1", title = "Tema")

        repository.record("t1", 5_000L, false, track)

        val latest = repository.getAll(1).first()
        assertEquals("t1", latest.trackId)
        assertEquals(5_000, latest.playedMs)
        assertEquals("Tema", latest.track?.title)
        assertEquals(1, server.requestCount)
    }
}
