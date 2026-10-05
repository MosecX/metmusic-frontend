import 'package:dio/dio.dart';

/// Jerarquía sellada de errores de red de MetMusic.
///
/// Todos los services de API lanzan subtipos de [ApiException]; la UI los
/// traduce a mensajes mediante [userMessage].
sealed class ApiException implements Exception {
  const ApiException({this.statusCode, this.uri});

  final int? statusCode;
  final Uri? uri;

  /// Detalle técnico del error.
  String get message;

  /// Mensaje mostrable al usuario (SnackBar / estado de error).
  String get userMessage;

  /// True si conviene ofrecer un botón de reintento.
  bool get isRetryable => true;

  @override
  String toString() => '$runtimeType($statusCode): $message';

  /// Construye la excepción adecuada a partir de un [DioException].
  static ApiException fromDio(DioException error) {
    final uri = error.requestOptions.uri;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return TimeoutApiException(uri: uri);
      case DioExceptionType.connectionError:
        return NetworkApiException(uri: uri);
      case DioExceptionType.cancel:
        return const CancelledApiException();
      case DioExceptionType.badCertificate:
        return NetworkApiException(
          uri: uri,
          message: 'Certificado del servidor inválido',
        );
      case DioExceptionType.badResponse:
        return _fromStatus(error, uri);
      case DioExceptionType.unknown:
        final text = (error.message ?? '').toLowerCase();
        if (text.contains('socket') || text.contains('failed host lookup')) {
          return NetworkApiException(uri: uri);
        }
        return UnknownApiException(
          error.message ?? 'Error desconocido',
          uri: uri,
        );
    }
  }

  static ApiException _fromStatus(DioException error, Uri uri) {
    final status = error.response?.statusCode ?? 0;
    final detail = _extractMessage(error.response?.data);
    switch (status) {
      case 400:
        return BadRequestApiException(
          detail ?? 'Solicitud inválida',
          statusCode: 400,
          uri: uri,
        );
      case 401:
      case 403:
        return UnauthorizedApiException(statusCode: status, uri: uri);
      case 404:
        return NotFoundApiException(detail, statusCode: 404, uri: uri);
      case 429:
        return ServerApiException(
          'Demasiadas solicitudes, esperá un momento',
          statusCode: 429,
          uri: uri,
        );
      case 502:
      case 503:
      case 504:
        return ServerApiException(
          'Error del servidor de música',
          statusCode: status,
          uri: uri,
        );
      default:
        if (status >= 500) {
          return ServerApiException(
            detail ?? 'Error del servidor',
            statusCode: status,
            uri: uri,
          );
        }
        return BadRequestApiException(
          detail ?? 'Error inesperado',
          statusCode: status,
          uri: uri,
        );
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      for (final key in ['detail', 'message', 'error', 'msg']) {
        final value = data[key];
        if (value is String && value.isNotEmpty) return value;
        if (value is Map && value['message'] is String) {
          return value['message'] as String;
        }
      }
    }
    if (data is String && data.isNotEmpty && data.length < 300) return data;
    return null;
  }
}

/// No hay conectividad o el host no responde.
class NetworkApiException extends ApiException {
  const NetworkApiException({
    super.statusCode,
    super.uri,
    this.message = 'Sin conexión al servidor',
  });

  @override
  final String message;

  @override
  String get userMessage => 'Sin conexión al servidor';
}

/// La operación superó el timeout (15 s connect / 30 s receive).
class TimeoutApiException extends ApiException {
  const TimeoutApiException({super.statusCode, super.uri});

  @override
  String get message => 'Tiempo de espera agotado';

  @override
  String get userMessage => 'El servidor tardó demasiado en responder';
}

/// Token ausente, inválido o expirado (401 / 403).
class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException({super.statusCode, super.uri});

  @override
  String get message => 'No autorizado';

  @override
  String get userMessage => 'Token inválido o expirado. Revisá Settings.';

  @override
  bool get isRetryable => false;
}

/// Recurso no encontrado (404).
class NotFoundApiException extends ApiException {
  const NotFoundApiException(String? detail, {super.statusCode, super.uri})
      : message = detail ?? 'Recurso no encontrado';

  @override
  final String message;

  @override
  String get userMessage => message == 'Recurso no encontrado'
      ? 'Track no disponible'
      : message;

  @override
  bool get isRetryable => false;
}

/// Petición mal formada (400).
class BadRequestApiException extends ApiException {
  const BadRequestApiException(this.message, {super.statusCode, super.uri});

  @override
  final String message;

  @override
  String get userMessage => message;

  @override
  bool get isRetryable => false;
}

/// Error del backend (5xx).
class ServerApiException extends ApiException {
  const ServerApiException(this.message, {super.statusCode, super.uri});

  @override
  final String message;

  @override
  String get userMessage => message;
}

/// Respuesta inválida o no parseable.
class ParseApiException extends ApiException {
  const ParseApiException(this.message);

  @override
  final String message;

  @override
  String get userMessage => 'Respuesta inesperada del servidor';
}

/// Petición cancelada por el cliente.
class CancelledApiException extends ApiException {
  const CancelledApiException();

  @override
  String get message => 'Petición cancelada';

  @override
  String get userMessage => 'Operación cancelada';

  @override
  bool get isRetryable => false;
}

/// Cualquier otro fallo no clasificado.
class UnknownApiException extends ApiException {
  const UnknownApiException(this.message, {super.uri, super.statusCode});

  @override
  final String message;

  @override
  String get userMessage => 'Ocurrió un error inesperado';
}
