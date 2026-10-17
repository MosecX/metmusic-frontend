package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed

/** Contenido completo de la Home. */
data class ExploreHome(val sections: List<ExploreSection> = emptyList()) {

    /** `true` cuando ninguna sección trae contenido. */
    val isEmpty: Boolean
        get() = sections.all { it.isEmpty }

    companion object {
        /** Claves de metadata que no son secciones. */
        private val SKIP_KEYS = setOf("total_results", "total", "count", "limit", "offset")

        /** Tolerante: acepta `{sections: [...]}` o un mapa de listas. */
        fun fromJson(raw: Any?): ExploreHome {
            if (raw is List<*>) {
                val sections = raw.mapIndexedNotNull { index, entry ->
                    when (entry) {
                        is Map<*, *> -> {
                            val map = entry.stringKeyed()
                            val id = JsonParse.strOr(map["id"] ?: map["key"], "section_$index")
                            ExploreSection.fromJson(id, entry)
                        }
                        is List<*> -> ExploreSection.fromJson("section_$index", entry)
                        else -> null
                    }
                }
                return ExploreHome(sections.filterNot { it.isEmpty })
            }

            if (raw is Map<*, *>) {
                val map = raw.stringKeyed()
                val explicit = map["sections"]
                if (explicit is List<*>) {
                    val home = fromJson(explicit)
                    if (!home.isEmpty) return home
                }

                val sections = map.entries.mapNotNull { (key, value) ->
                    if (key in SKIP_KEYS) return@mapNotNull null
                    if (value !is List<*> && value !is Map<*, *>) return@mapNotNull null
                    ExploreSection.fromJson(key, value).takeIf { !it.isEmpty }
                }
                return ExploreHome(sections)
            }

            return ExploreHome()
        }
    }
}
