import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// Un servicio reportado por `GET /api/health`.
class HealthServiceStatus {
  const HealthServiceStatus({
    required this.id,
    required this.name,
    required this.ok,
    this.latencyMs,
    this.detail,
  });

  final String id;
  final String name;
  final bool ok;
  final double? latencyMs;
  final String? detail;

  factory HealthServiceStatus.fromJson(Map<String, dynamic> json) {
    return HealthServiceStatus(
      id: Json.strOr(json['id'], ''),
      name: Json.strOr(json['name'], Json.strOr(json['id'], '')),
      ok: Json.boolOr(json['ok'], true),
      latencyMs: Json.asDouble(json['latency_ms']),
      detail: Json.str(json['detail']),
    );
  }
}

/// Resultado de `GET /api/health`.
class HealthStatus {
  const HealthStatus({
    required this.ok,
    this.status,
    this.version,
    this.providers,
    this.services = const [],
    this.uptimeSeconds,
    this.raw,
  });

  final bool ok;
  final String? status;
  final String? version;
  final Map<String, dynamic>? providers;

  /// Estado por servicio (catálogo, stream, caché…).
  final List<HealthServiceStatus> services;
  final double? uptimeSeconds;
  final Map<String, dynamic>? raw;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      ok: Json.boolOr(
          json['ok'] ?? json['healthy'] ?? json['status'] == 'ok', true),
      status: Json.str(json['status']),
      version: Json.str(json['version']),
      providers: json['providers'] is Map
          ? Map<String, dynamic>.from(json['providers'] as Map)
          : null,
      services: Json.listAt(json, 'services')
          .map(HealthServiceStatus.fromJson)
          .toList(growable: false),
      uptimeSeconds: Json.asDouble(json['uptime_seconds']),
      raw: json,
    );
  }

  String get summary {
    final parts = <String>[
      ok ? 'Servidor OK' : 'Servidor con problemas',
      if (version != null) 'v$version',
      if (services.isNotEmpty)
        '${services.where((s) => s.ok).length}/${services.length} servicios OK',
      if (providers != null && providers!.isNotEmpty)
        providers!.entries.map((e) => '${e.key}: ${e.value}').join(', '),
    ];
    return parts.join(' • ');
  }
}

/// Servicio de salud y mantenimiento del backend.
class HealthService {
  HealthService(this._client);

  final ApiClient _client;

  /// `GET /api/health` (no requiere auth).
  Future<HealthStatus> check() async {
    final data = await _client.getJson(
      ApiEndpoints.health,
      receiveTimeout: const Duration(seconds: 10),
    );
    return HealthStatus.fromJson(Json.mapOf(data));
  }

  /// `DELETE /api/cache` — limpia la caché del servidor.
  Future<void> clearServerCache() async {
    await _client.deleteJson(ApiEndpoints.cache);
  }
}
