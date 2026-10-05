import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'glass_card.dart';

/// Estado de error reutilizable, con mensaje legible y botón de reintento.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  String get _message {
    final e = error;
    if (e is ApiException) return e.userMessage;
    return 'Ocurrió un error inesperado';
  }

  String get _detail {
    final e = error;
    if (e is ApiException) {
      if (e is UnauthorizedApiException) return 'Abrí Settings para actualizar el token.';
      if (e is NetworkApiException) return 'Verificá tu conexión y la URL del backend.';
      if (e is ServerApiException) return 'El backend respondió con error ${e.statusCode ?? ''}.';
    }
    return e.toString();
  }

  bool get _canRetry {
    final e = error;
    if (e is ApiException) return e.isRetryable;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(error),
                size: 40,
                color: AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: AppTextStyles.title,
              ),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  _detail,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
              if (onRetry != null && _canRetry) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, curve: Curves.easeOutCubic),
      ),
    );
  }

  IconData _iconFor(Object error) {
    if (error is UnauthorizedApiException) return LucideIcons.lock;
    if (error is NetworkApiException || error is TimeoutApiException) {
      return LucideIcons.wifiOff;
    }
    if (error is NotFoundApiException) return LucideIcons.music;
    if (error is ServerApiException) return LucideIcons.alertTriangle;
    return LucideIcons.alertCircle;
  }
}
