import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Extensiones de conveniencia para [BuildContext].
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Muestra un SnackBar flotante con el estilo de la app.
  void showSnack(String message, {bool isError = false, SnackBarAction? action}) {
    final messenger = ScaffoldMessenger.maybeOf(this);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                size: 18,
                color: isError ? AppColors.danger : AppColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: AppTextStyles.body)),
            ],
          ),
          action: action,
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
  }
}

/// Extensiones numéricas para layout responsivo.
extension NumX on num {
  double get h => toDouble();
  SizedBox get vGap => SizedBox(height: toDouble());
  SizedBox get hGap => SizedBox(width: toDouble());
}

/// Helpers de parseo seguro de JSON.
class Json {
  Json._();

  static String? str(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static String strOr(dynamic value, String fallback) => str(value) ?? fallback;

  static int? asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int intOr(dynamic value, int fallback) => asInt(value) ?? fallback;

  static bool boolOr(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static double? asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Convierte una lista dinámica de objetos JSON en una lista de mapas.
  static List<Map<String, dynamic>> maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }

  /// Convierte una lista dinámica de strings.
  static List<String> strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList(growable: false);
  }

  /// Lee una lista de objetos desde `json[key]`.
  static List<Map<String, dynamic>> listAt(Map<String, dynamic> json, String key) =>
      maps(json[key]);

  /// Normaliza una respuesta dinámica a un mapa.
  static Map<String, dynamic> mapOf(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
