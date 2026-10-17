package com.metmusic.metmusic.core.data.fake

import com.metmusic.metmusic.core.data.local.dao.UserPlaylistDao
import com.metmusic.metmusic.core.data.local.entity.UserPlaylistEntity
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** UserPlaylistDao en memoria para tests JVM: sin Room y sin Android. */
class FakeUserPlaylistDao : UserPlaylistDao {

    private val mutex = Mutex()
    private val entries = linkedMapOf<String, UserPlaylistEntity>()

    override suspend fun insert(entity: UserPlaylistEntity) {
        mutex.withLock { entries[entity.id] = entity }
    }

    override suspend fun insertAll(entities: List<UserPlaylistEntity>) {
        mutex.withLock { entities.forEach { entries[it.id] = it } }
    }

    override suspend fun getAll(): List<UserPlaylistEntity> = mutex.withLock {
        entries.values.sortedBy { it.name.lowercase() }
    }

    override suspend fun getById(id: String): UserPlaylistEntity? = mutex.withLock {
        entries[id]
    }

    override suspend fun deleteById(id: String) {
        mutex.withLock { entries.remove(id) }
    }

    override suspend fun clear() {
        mutex.withLock { entries.clear() }
    }
}
