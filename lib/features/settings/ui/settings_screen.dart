import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/settings_provider.dart';

/// Ajustes: estado de la API, calidad de audio, letras, caché y acerca de.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 180),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 16),
          child: Text('Ajustes', style: AppTextStyles.headline),
        ),

        // --- Estado de los servicios ---
        const _Section(
          title: 'Estado de los servicios',
          icon: LucideIcons.server,
          children: [_ServicesStatus()],
        ),
        const SizedBox(height: 16),

        // --- Calidad ---
        _Section(
          title: 'Calidad de audio',
          icon: LucideIcons.signal,
          children: [
            for (final quality in AudioQualityPreference.values)
              _QualityOption(
                label: quality.label,
                selected: quality == settings.audioQuality,
                onTap: () => controller.setAudioQuality(quality),
              ),
            const Text(
              'Se envía como parámetro al resolver cada stream.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Letras ---
        _Section(
          title: 'Letras',
          icon: LucideIcons.captions,
          children: [
            const Text(
              'Elegí cómo se muestran las letras sincronizadas en el '
              'reproductor.',
              style: AppTextStyles.caption,
            ),
            for (final mode in LyricsMode.values)
              _QualityOption(
                label: mode.label,
                selected: mode == settings.lyricsMode,
                onTap: () => controller.setLyricsMode(mode),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Tema ---
        const _Section(
          title: 'Tema',
          icon: LucideIcons.moon,
          children: [
            Row(
              children: [
                Icon(LucideIcons.moon, size: 16, color: AppColors.accent),
                SizedBox(width: 10),
                Expanded(
                  child:
                      Text('Oscuro siempre activo', style: AppTextStyles.body),
                ),
                Text('Único', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Caché ---
        _Section(
          title: 'Caché',
          icon: LucideIcons.trash2,
          children: [
            const Text(
              'Limpia la caché de metadatos y streams del servidor.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _clearCache(controller),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text('Limpiar caché del servidor'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Acerca de ---
        _Section(
          title: 'Acerca de',
          icon: LucideIcons.info,
          children: [
            const _InfoRow(label: 'Aplicación', value: AppConstants.appName),
            const _InfoRow(label: 'Versión', value: AppConstants.appVersion),
            _InfoRow(
              label: 'Backend',
              value: settings.baseUrl.replaceFirst('https://', ''),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cliente personal de música. Metadatos vía Tidal, streaming de alta '
              'calidad vía Qobuz, resueltos por un backend autohospedado.',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _clearCache(SettingsController controller) async {
    try {
      await LoadingOverlay.show(
        context,
        controller.clearServerCache(),
        message: 'Limpiando caché…',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caché del servidor limpiada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo limpiar la caché')),
        );
      }
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? LucideIcons.check : LucideIcons.circle,
              size: 18,
              color: selected ? AppColors.accent : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de los servicios del backend (`GET /api/health`): resumen general,
/// cada servicio con su estado/latencia/detalle y un botón para refrescar.
class _ServicesStatus extends ConsumerWidget {
  const _ServicesStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);
    return health.when(
      loading: () => const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Consultando el estado…', style: AppTextStyles.caption),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ResultRow(
            icon: LucideIcons.alertTriangle,
            color: AppColors.danger,
            text: 'No se pudo consultar el estado del backend.',
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => ref.invalidate(apiHealthProvider),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Reintentar'),
          ),
        ],
      ),
      data: (status) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultRow(
            icon: status.ok ? LucideIcons.check : LucideIcons.alertTriangle,
            color: status.ok ? AppColors.accent : AppColors.danger,
            text: status.summary,
          ),
          if (status.uptimeSeconds != null)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                'Uptime ${_formatUptime(status.uptimeSeconds!)}',
                style: AppTextStyles.caption,
              ),
            ),
          if (status.services.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final service in status.services)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          service.ok ? LucideIcons.check : LucideIcons.x,
                          size: 14,
                          color:
                              service.ok ? AppColors.accent : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service.name,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13.5,
                              color: service.ok
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (service.latencyMs != null)
                          Text(
                            '${service.latencyMs!.toStringAsFixed(0)} ms',
                            style: AppTextStyles.caption,
                          ),
                      ],
                    ),
                    if (service.detail != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 22, top: 2),
                        child: Text(
                          service.detail!,
                          style: AppTextStyles.caption,
                        ),
                      ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => ref.invalidate(apiHealthProvider),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  String _formatUptime(double seconds) {
    final total = seconds.toInt();
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours <= 0) return '$minutes min';
    return '$hours h $minutes min';
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
