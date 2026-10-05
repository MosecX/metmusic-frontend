import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/extensions.dart';

/// Resultado de `GET /api/health`.
class HealthStatus {
  const HealthStatus({
    required this.ok,
    this.status,
    this.version,
    this.providers,
    this.raw,
  });

  final bool ok;
  final String? status;
  final String? version;
  final Map<String, dynamic>? providers;
  final Map<String, dynamic>? raw;

  factory HealthStatus.fromJson(Map<String, dynamic> json) {
    return HealthStatus(
      ok: Json.boolOr(json['ok'] ?? json['healthy'] ?? json['status'] == 'ok', true),
      status: Json.str(json['status']),
      version: Json.str(json['version']),
      providers: json['providers'] is Map
          ? Map<String, dynamic>.from(json['providers'] as Map)
          : null,
      raw: json,
    );
  }

  String get summary {
    final parts = <String>['Servidor OK'];
    if (version != null) parts.add('v$version');
    if (providers != null && providers!.isNotEmpty) {
      parts.add(providers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', '));
    }
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
