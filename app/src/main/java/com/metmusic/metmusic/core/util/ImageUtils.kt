package com.metmusic.metmusic.core.util

import com.metmusic.metmusic.core.model.Thumbnail

/** Utilidades para seleccionar la mejor imagen disponible. */
object ImageUtils {

    /** Devuelve la URL de la miniatura cuyo ancho se acerque más a [targetSize]. */
    fun bestThumbnail(thumbnails: List<Thumbnail>, targetSize: Int): String {
        // Las entradas sin URL no sirven para decidir: se descartan antes de
        // ordenar para no arrastrar un ancho `null` (que sortea como 0).
        val usable = thumbnails.filter { it.url.isNotEmpty() }
        if (usable.isEmpty()) return ""

        val sized = usable.filter { (it.width ?: 0) > 0 }
        if (sized.isEmpty()) {
            // El backend no manda ancho: no se puede elegir por tamaño, se usa
            // la última (en estos catálogos viene de mayor a menor).
            return usable.last().url
        }

        val sorted = sized.sortedBy { it.width ?: 0 }
        for (thumbnail in sorted) {
            if ((thumbnail.width ?: 0) >= targetSize) return thumbnail.url
        }
        return sorted.last().url
    }

    /** Miniatura para listas (48–64 dp). */
    fun listThumbnail(thumbnails: List<Thumbnail>): String = bestThumbnail(thumbnails, 160)

    /** Miniatura para cards y headers. */
    fun cardThumbnail(thumbnails: List<Thumbnail>): String = bestThumbnail(thumbnails, 640)

    /**
     * Miniatura de artista.
     *
     * El catálogo sólo publica imágenes de artista hasta 750x750: pedir más
     * devuelve un 404 y el artwork no aparece nunca.
     */
    fun artistThumbnail(thumbnails: List<Thumbnail>): String = bestThumbnail(thumbnails, 750)

    /** Artwork grande para el reproductor. */
    fun largeArtwork(thumbnails: List<Thumbnail>): String = bestThumbnail(thumbnails, 750)

    /** Base del CDN de imágenes de Tidal. */
    const val tidalImageBase = "https://resources.tidal.com/images"

    /**
     * Lado máximo que el CDN de Tidal sirve para las imágenes de artista.
     *
     * 640x640 y 1280x1280 devuelven 403; 750x750 es el tope real.
     */
    const val artistImageSize = 750

    /**
     * Convierte el `picture` de un artista en una URL servible.
     *
     * El backend devuelve el identificador del artwork **desnudo**, sin
     * protocolo ni host: `"65d23ddc-7b3b-4b17-bc84-b02832ddc204"`. Pasarlo
     * tal cual nunca carga: el CDN de Tidal indexa esas imágenes por el UUID
     * con los guiones reemplazados por `/`, y la última URL segment es el
     * tamaño: `https://resources.tidal.com/images/65d23ddc/7b3b/4b17/bc84/b02832ddc204/750x750.jpg`
     */
    fun artistImageUrl(picture: String, size: Int = artistImageSize): String {
        if (picture.isEmpty()) return ""

        // Si el backend ya devuelve una URL absoluta, se respeta tal cual.
        if (picture.startsWith("http://") || picture.startsWith("https://")) {
            return picture
        }

        return "$tidalImageBase/${picture.replace('-', '/')}/${size}x$size.jpg"
    }
}
