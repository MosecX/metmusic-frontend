package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse
import com.metmusic.metmusic.core.util.stringKeyed

/** Resultado de `GET /api/health`. */
data class HealthStatus(
    val ok: Boolean,
    val status: String? = null,
    val version: String? = null,
    val providers: Map<String, Any?>? = null,
    /** Estado por servicio (catálogo, stream, caché...). */
    val services: List<HealthServiceStatus> = emptyList(),
    val uptimeSeconds: Double? = null,
    /** Payload crudo, para el diagnóstico del arranque. */
    val raw: Map<String, Any?>? = null,
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): HealthStatus = HealthStatus(
            ok = JsonParse.boolOr(json["ok"] ?: json["healthy"] ?: (json["status"] == "ok"), true),
            status = JsonParse.str(json["status"]),
            version = JsonParse.str(json["version"]),
            providers = (json["providers"] as? Map<*, *>)?.stringKeyed(),
            services = JsonParse.listAt(json, "services").map { HealthServiceStatus.fromJson(it) },
            uptimeSeconds = JsonParse.asDouble(json["uptime_seconds"]),
            raw = json,
        )
    }
}
