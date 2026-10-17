package com.metmusic.metmusic.core.data.fake

import com.metmusic.metmusic.core.data.local.dao.HistoryDao
import com.metmusic.metmusic.core.data.local.entity.HistoryEntity
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** DAO de historial en memoria para tests JVM: sin Room y sin Android. */
class FakeHistoryDao : HistoryDao {

    private val mutex = Mutex()
    private val entries = mutableListOf<HistoryEntity>()
    private var nextId = 1L

    override suspend fun insert(entity: HistoryEntity): Long = mutex.withLock {
        val id = if (entity.id == 0L) nextId++ else entity.id
        entries += entity.copy(id = id)
        id
    }

    override suspend fun getAll(limit: Int): List<HistoryEntity> = mutex.withLock {
        entries.sortedByDescending { it.playedAt }.take(limit)
    }

    override suspend fun getAllNoLimit(): List<HistoryEntity> = mutex.withLock {
        entries.sortedByDescending { it.playedAt }
    }

    override suspend fun latest(): HistoryEntity? = mutex.withLock {
        entries.maxByOrNull { it.playedAt }
    }

    override suspend fun trimTo(maxEntries: Int) {
        mutex.withLock {
            val keep = entries.sortedByDescending { it.playedAt }
                .take(maxEntries)
                .map { it.id }
                .toSet()
            entries.removeAll { it.id !in keep }
        }
    }

    override suspend fun clear() {
        mutex.withLock { entries.clear() }
    }

    override suspend fun count(): Int = mutex.withLock { entries.size }
}
