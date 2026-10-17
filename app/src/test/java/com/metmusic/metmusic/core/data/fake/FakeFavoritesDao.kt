package com.metmusic.metmusic.core.data.fake

import com.metmusic.metmusic.core.data.local.dao.FavoritesDao
import com.metmusic.metmusic.core.data.local.entity.FavoritesEntity
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** DAO de favoritos en memoria para tests JVM: sin Room y sin Android. */
class FakeFavoritesDao : FavoritesDao {

    private val mutex = Mutex()
    private val entries = linkedMapOf<String, FavoritesEntity>()

    override suspend fun insert(entity: FavoritesEntity) {
        mutex.withLock { entries[entity.trackId] = entity }
    }

    override suspend fun deleteByTrackId(trackId: String) {
        mutex.withLock { entries.remove(trackId) }
    }

    override suspend fun exists(trackId: String): Boolean = mutex.withLock {
        entries.containsKey(trackId)
    }

    override suspend fun getAll(): List<FavoritesEntity> = mutex.withLock {
        entries.values.sortedByDescending { it.addedAt }
    }

    override suspend fun clear() {
        mutex.withLock { entries.clear() }
    }

    override suspend fun count(): Int = mutex.withLock { entries.size }
}
