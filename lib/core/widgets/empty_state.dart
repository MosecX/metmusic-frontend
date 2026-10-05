import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Estado vacío reutilizable (icono + título + subtítulo + acción opcional).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(icon, size: 34, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.title),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
      ),
    );
  }
}
