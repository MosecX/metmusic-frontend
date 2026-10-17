import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass_styles.dart';

/// Overlay modal de carga con blur, para bloquear la UI durante una operación.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});

  final String? message;

  /// Muestra el overlay mientras se resuelve [future].
  static Future<T> show<T>(
    BuildContext context,
    Future<T> future, {
    String? message,
  }) async {
    // No se espera el Future: el diálogo se cierra en el `finally`.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        builder: (_) => LoadingOverlay(message: message),
      ),
    );
    try {
      return await future;
    } finally {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GlassStyles.cardBorderRadius),
          child: BackdropFilter(
            filter: GlassStyles.blurFilter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: GlassStyles.playerDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accent,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(message!, style: const TextStyle(color: Colors.white)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Spinner centrado simple para usar dentro de secciones.
class GlassLoader extends StatelessWidget {
  const GlassLoader({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
