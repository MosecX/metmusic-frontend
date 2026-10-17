package com.metmusic.metmusic.core.data

import com.metmusic.metmusic.core.data.local.dao.MixFavoritesDao
import com.metmusic.metmusic.core.data.local.entity.MixFavoritesEntity
import com.metmusic.metmusic.core.model.RadioMix
import com.metmusic.metmusic.core.model.SavedMix
import javax.inject.Inject
import javax.inject.Singleton

/** Mixes (radios) favoritos: solo locales, sin sync con el backend. */
@Singleton
class MixFavoritesRepository @Inject constructor(
    private val dao: MixFavoritesDao,
) {
    suspend fun isFavorite(trackId: String): Boolean = dao.exists(trackId)

    /** Mixes guardados, más nuevos primero. */
    suspend fun getAll(): List<SavedMix> = dao.getAll().map { it.toSavedMix() }

    /** Alterna el estado y devuelve el nuevo valor (true = guardado). */
    suspend fun toggle(trackId: String, mix: RadioMix): Boolean {
        if (dao.exists(trackId)) {
            dao.deleteByTrackId(trackId)
            return false
        }
        dao.insert(
            MixFavoritesEntity(
                trackId = trackId,
                mixId = mix.id,
                title = mix.title,
                subTitle = mix.subTitle,
                description = mix.description,
                imageUrl = mix.imageUrl,
                addedAt = System.currentTimeMillis(),
            ),
        )
        return true
    }

    suspend fun remove(trackId: String) {
        dao.deleteByTrackId(trackId)
    }
}

/** Reconstruye el mix guardado desde la fila local. */
private fun MixFavoritesEntity.toSavedMix(): SavedMix = SavedMix(
    trackId = trackId,
    mix = RadioMix(
        id = mixId,
        title = title,
        subTitle = subTitle,
        description = description,
        imageUrl = imageUrl,
    ),
)
