import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP central de MetMusic.
///
/// Envuelve Dio con interceptores de URL base, auth Bearer, reintento
/// (1 intento para metadatos, nunca para `/api/stream`) y logging en debug.
class ApiClient {
  ApiClient({required this.baseUrl, required this.token}) {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        responseType: ResponseType.json,
        contentType: Headers.jsonContentType,
        headers: const {'Accept': 'application/json'},
        // No seguir redirecciones infinitas en el resolver de streams.
        followRedirects: true,
        maxRedirects: 5,
      ),
    );

    dio.interceptors.addAll([
      BaseUrlInterceptor(baseUrl),
      AuthInterceptor(token),
      _RetryInterceptor(dio),        if (kDebugMode) _LoggingInterceptor(),
    ]);
  }

  final BaseUrlHolder baseUrl;
  final ApiTokenHolder token;
  late final Dio dio;

  // --- Helpers tipados ---

  /// GET que devuelve el JSON decodificado (Map o List).
  Future<dynamic> getJson(
    String path, {
    Map<String, dynamic>? query,
    Duration? receiveTimeout,
  }) {
    return _guard(() => dio.get<dynamic>(
          path,
          queryParameters: query,
          options: Options(receiveTimeout: receiveTimeout),
        ));
  }

  /// POST con body JSON.
  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _guard(() => dio.post<dynamic>(path, data: body, queryParameters: query));
  }

  /// PUT con body JSON.
  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _guard(() => dio.put<dynamic>(path, data: body, queryParameters: query));
  }

  /// DELETE (opcionalmente con body).
  Future<dynamic> deleteJson(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) {
    return _guard(() => dio.delete<dynamic>(path, data: body, queryParameters: query));
  }

  /// Ejecuta una request y traduce cualquier [DioException] a [ApiException].
  Future<T> _guard<T>(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw UnknownApiException(error.toString());
    }
  }

  /// True si el cliente puede alcanzar el backend (usado para modo offline).
  Future<bool> ping() async {
    try {
      await getJson(ApiEndpoints.health,
          receiveTimeout: const Duration(seconds: 6));
      return true;
    } on ApiException {
      return false;
    }
  }

  void dispose() => dio.close(force: true);
}

/// Reintenta UNA vez las peticiones de metadatos que fallan por red o 5xx.
/// Nunca reintenta `/api/stream` (las URLs de stream son de un solo uso).
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;
  static const String _retryCountKey = 'metmusic_retry_count';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isStream = options.path.contains('/stream/');
    final isGet = options.method.toUpperCase() == 'GET';
    final status = err.response?.statusCode ?? 0;
    final retryable = err.type != DioExceptionType.cancel &&
        (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout ||
            status >= 500);
    final attempt = (options.extra[_retryCountKey] as int?) ?? 0;

    if (!isStream && isGet && retryable && attempt < 1) {
      options.extra[_retryCountKey] = attempt + 1;
      try {
        final response = await _dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } on DioException catch (error) {
        return handler.next(error);
      }
    }
    handler.next(err);
  }
}

/// Logging de requests en modo debug.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    developer.log(
      '→ ${options.method} ${options.baseUrl}${options.path}'
      '${options.queryParameters.isEmpty ? '' : ' ?${options.queryParameters}'}',
      name: 'http',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    developer.log(
      '← ${response.statusCode} ${response.requestOptions.path}',
      name: 'http',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '✗ ${err.type.name} ${err.requestOptions.path} ${err.message ?? ''}',
      name: 'http',
    );
    handler.next(err);
  }
}
