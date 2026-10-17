package com.metmusic.metmusic.feature.player

import com.metmusic.metmusic.core.data.SettingsRepository
import com.metmusic.metmusic.core.data.StreamRepository
import com.metmusic.metmusic.core.model.StreamInfo
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first

/**
 * Resuelve la URL de reproducción de una pista con la calidad elegida.
 *
 * Sin cache ni retry: cada reproducción pide una URL nueva al backend (la
 * resiliencia ante URLs expiradas llega en una fase posterior con
 * [PlayerConnection] como punto de carga).
 */
@Singleton
class StreamResolver @Inject constructor(
    private val streamRepository: StreamRepository,
    private val settingsRepository: SettingsRepository,
) {
    /** Lee la calidad actual de Settings y resuelve el stream de [trackId]. */
    suspend fun resolve(trackId: String): StreamInfo {
        val quality = settingsRepository.settings.first().audioQuality
        return streamRepository.getStream(trackId, quality)
    }
}
