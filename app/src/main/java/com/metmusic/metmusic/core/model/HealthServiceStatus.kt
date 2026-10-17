package com.metmusic.metmusic.core.model

import com.metmusic.metmusic.core.util.JsonParse

/** Un servicio reportado por `GET /api/health`. */
data class HealthServiceStatus(
    val id: String,
    val name: String,
    val ok: Boolean,
    val latencyMs: Double? = null,
    val detail: String? = null,
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): HealthServiceStatus = HealthServiceStatus(
            id = JsonParse.strOr(json["id"], ""),
            name = JsonParse.strOr(json["name"], JsonParse.strOr(json["id"], "")),
            ok = JsonParse.boolOr(json["ok"], true),
            latencyMs = JsonParse.asDouble(json["latency_ms"]),
            detail = JsonParse.str(json["detail"]),
        )
    }
}
