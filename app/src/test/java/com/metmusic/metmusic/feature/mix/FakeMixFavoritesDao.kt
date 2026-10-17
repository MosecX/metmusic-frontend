package com.metmusic.metmusic.feature.mix

import com.metmusic.metmusic.core.data.local.dao.MixFavoritesDao
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Implementación en memoria de MixFavoritesDao para pruebas JVM. */
class FakeMixFavoritesDao : MixFavoritesDao {

    private val mutex = Mutex()
    private val entries = linkedMapOf<String, MixFavoritesEntity>()

    override suspend fun insert(entity: MixFavoritesEntity) {
        mutex.withLock { entries[entity.trackId] = entity }
    }

    override suspend fun deleteByTrackId(trackId: String) {
        mutex.withLock { entries.remove(trackId) }
    }

    override suspend fun exists(trackId: String): Boolean = mutex.withLock {
        entries.containsKey(trackId)
    }

    override suspend fun getAll(): List<MixFavoritesEntity> = mutex.withLock {
        entries.values.sortedByDescending { it.addedAt }
    }

    override suspend fun clear() {
        mutex.withLock { entries.clear() }
    }
}
