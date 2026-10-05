import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'api_endpoints.dart';

/// Mantiene el token Bearer activo en memoria.
///
/// Se hidrata desde SharedPreferences al arrancar y se actualiza desde
/// Settings. Es un [ValueNotifier] para que la UI pueda reaccionar.
class ApiTokenHolder extends ValueNotifier<String> {
  ApiTokenHolder([super.value = ApiConstants.defaultApiToken]);

  void update(String token) => value = token;
}

/// Mantiene la URL base activa (configurable desde Settings).
class BaseUrlHolder extends ValueNotifier<String> {
  BaseUrlHolder([String initial = ApiConstants.baseUrl])
      : super(_normalize(initial));

  void update(String url) => value = _normalize(url);

  static String _normalize(String url) {
    var value = url.trim();
    if (value.isEmpty) return ApiConstants.baseUrl;
    if (value.endsWith('/')) value = value.substring(0, value.length - 1);
    return value;
  }
}

/// Inyecta `Authorization: Bearer {token}` en toda request a `/api/*`,
/// excepto en `/api/health` que no requiere autenticación.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenHolder);

  final ApiTokenHolder _tokenHolder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.path;
    final needsAuth = path.startsWith(ApiEndpoints.prefix) &&
        !path.startsWith(ApiEndpoints.health);
    if (needsAuth) {
      final token = _tokenHolder.value.trim();
      if (token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}

/// Aplica la URL base configurable en tiempo de ejecución.
class BaseUrlInterceptor extends Interceptor {
  BaseUrlInterceptor(this._baseUrlHolder);

  final BaseUrlHolder _baseUrlHolder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.path.startsWith('http')) {
      options.baseUrl = _baseUrlHolder.value;
    }
    handler.next(options);
  }
}
