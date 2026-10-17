package com.metmusic.metmusic.core.util

import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.isString
import kotlinx.serialization.json.longOrNull

/**
 * Helpers de parseo tolerante de JSON, port de `Json` (Flutter).
 *
 * `parse` decodifica con kotlinx.serialization (`lenient`, `ignoreUnknownKeys`)
 * a mapas nativos (`Map<String, Any?>`); los modelos se construyen con
 * `fromJson` tolerante, sin acoplar data classes `@Serializable` al backend.
 */
object JsonParse {

    private val json = Json {
        isLenient = true
        ignoreUnknownKeys = true
    }

    fun str(value: Any?): String? {
        if (value == null) return null
        val text = value.toString()
        return text.ifEmpty { null }
    }

    fun strOr(value: Any?, fallback: String): String = str(value) ?: fallback

    fun asInt(value: Any?): Int? = when (value) {
        null -> null
        is Int -> value
        is Number -> value.toInt()
        else -> value.toString().toIntOrNull()
    }

    fun intOr(value: Any?, fallback: Int): Int = asInt(value) ?: fallback

    fun asLong(value: Any?): Long? = when (value) {
        null -> null
        is Long -> value
        is Number -> value.toLong()
        else -> value.toString().toLongOrNull()
    }

    fun longOr(value: Any?, fallback: Long): Long = asLong(value) ?: fallback

    fun boolOr(value: Any?, fallback: Boolean): Boolean = when (value) {
        is Boolean -> value
        is Number -> value.toDouble() != 0.0
        is String -> value.lowercase() == "true"
        else -> fallback
    }

    fun asDouble(value: Any?): Double? = when (value) {
        null -> null
        is Number -> value.toDouble()
        else -> value.toString().toDoubleOrNull()
    }

    /** Convierte una lista dinámica de objetos JSON en una lista de mapas. */
    fun maps(value: Any?): List<Map<String, Any?>> {
        val list = value as? List<*> ?: return emptyList()
        return list.mapNotNull { item -> (item as? Map<*, *>)?.stringKeyed() }
    }

    /** Convierte una lista dinámica de valores en una lista de strings. */
    fun strings(value: Any?): List<String> {
        val list = value as? List<*> ?: return emptyList()
        return list.map { it.toString() }
    }

    /** Lee una lista de objetos desde `map[key]`. */
    fun listAt(map: Map<String, Any?>, key: String): List<Map<String, Any?>> = maps(map[key])

    /** Normaliza una respuesta dinámica a un mapa con claves String. */
    fun mapOf(value: Any?): Map<String, Any?> =
        (value as? Map<*, *>)?.stringKeyed() ?: emptyMap()

    /**
     * Decodifica un payload crudo a mapa. Devuelve `null` si el JSON es
     * inválido o si la raíz no es un objeto.
     */
    fun parse(raw: String): Map<String, Any?>? {
        val element = try {
            json.parseToJsonElement(raw)
        } catch (_: Exception) {
            return null
        }
        return when (val value = element.toKotlin()) {
            is Map<*, *> -> value.stringKeyed()
            else -> null
        }
    }

    /** Serializa mapas, listas y valores a JSON (para extras de `MediaItem`). */
    fun encode(value: Any?): String =
        json.encodeToString(JsonElement.serializer(), value.toJsonElement())

    private fun JsonElement.toKotlin(): Any? = when (val value = this) {
        is JsonNull -> null
        is JsonPrimitive -> when {
            value.isString -> value.content
            value.booleanOrNull != null -> value.booleanOrNull
            value.longOrNull != null -> value.longOrNull
            value.doubleOrNull != null -> value.doubleOrNull
            else -> value.content
        }
        is JsonObject -> buildMap {
            for ((key, item) in value) put(key, item.toKotlin())
        }
        is JsonArray -> value.map { it.toKotlin() }
    }

    private fun Any?.toJsonElement(): JsonElement = when (val value = this) {
        null -> JsonNull
        is JsonElement -> value
        is Boolean -> JsonPrimitive(value)
        is Number -> JsonPrimitive(value)
        is String -> JsonPrimitive(value)
        is Map<*, *> -> JsonObject(
            buildMap {
                for ((key, item) in value) put(key.toString(), item.toJsonElement())
            },
        )
        is Iterable<*> -> JsonArray(value.map { it.toJsonElement() })
        else -> JsonPrimitive(value.toString())
    }
}

/** Normaliza un mapa de claves dinámicas a claves String (port de `Map.from`). */
fun Map<*, *>.stringKeyed(): Map<String, Any?> =
    buildMap(size) { for ((key, value) in this@stringKeyed) put(key.toString(), value) }
