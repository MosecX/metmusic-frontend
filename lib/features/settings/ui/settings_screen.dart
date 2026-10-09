import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/settings_provider.dart';

/// Ajustes en grupos iOS: servicios, reproducción, apariencia y acerca de.
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
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: AppConstants.shellBottomInset,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 4),
          child: Text('Ajustes', style: AppTextStyles.largeTitle),
        ),

        // --- Servicios ---
        const _GroupLabel('Servicios'),
        const _Group(children: [_ServicesStatus()]),

        // --- Reproducción ---
        const _GroupLabel('Reproducción'),
        _Group(
          children: _withSeparators([
            _SettingsRow(
              icon: LucideIcons.volume2,
              badge: const Color(0xFF0A84FF),
              label: 'Calidad de audio',
              value: settings.audioQuality.label,
              chevron: true,
              onTap: () => _pickOption(
                title: 'Calidad de audio',
                options: AudioQualityPreference.values,
                labelOf: (q) => q.label,
                current: settings.audioQuality,
                onPick: controller.setAudioQuality,
              ),
            ),
            _SettingsRow(
              icon: LucideIcons.captions,
              badge: const Color(0xFFFF375F),
              label: 'Letras',
              value: settings.lyricsMode.label,
              chevron: true,
              onTap: () => _pickOption(
                title: 'Letras',
                options: LyricsMode.values,
                labelOf: (m) => m.label,
                current: settings.lyricsMode,
                onPick: controller.setLyricsMode,
              ),
            ),
          ]),
        ),

        // --- Apariencia ---
        const _GroupLabel('Apariencia'),
        _Group(
          children: _withSeparators([
            const _SettingsRow(
              icon: LucideIcons.slidersHorizontal,
              badge: Color(0xFF636366),
              label: 'Tema',
              value: 'Oscuro',
            ),
            _SettingsRow(
              icon: LucideIcons.trash2,
              badge: const Color(0xFFFF9F0A),
              label: 'Limpiar caché del servidor',
              onTap: () => _clearCache(controller),
            ),
          ]),
        ),

        // --- Acerca de ---
        const _GroupLabel('Acerca de'),
        _Group(
          children: _withSeparators([
            const _SettingsRow(
              icon: LucideIcons.info,
              badge: Color(0xFF34C759),
              label: 'Aplicación',
              value: AppConstants.appName,
            ),
            const _SettingsRow(
              icon: LucideIcons.gitBranch,
              badge: Color(0xFF636366),
              label: 'Versión',
              value: AppConstants.appVersion,
            ),
            _SettingsRow(
              icon: LucideIcons.server,
              badge: const Color(0xFF5E5CE6),
              label: 'Backend',
              value: settings.baseUrl.replaceFirst('https://', ''),
            ),
          ]),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Cliente personal de música. Metadatos vía Tidal, streaming de alta '
            'calidad vía Qobuz, resueltos por un backend autohospedado.',
            style: AppTextStyles.cardSubtitle,
          ),
        ),
      ],
    );
  }

  Future<void> _pickOption<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T current,
    required ValueChanged<T> onPick,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: RadioGroup<T>(
          groupValue: current,
          onChanged: (value) {
            if (value == null) return;
            onPick(value);
            Navigator.of(context).pop();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                RadioListTile<T>(
                  value: option,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(labelOf(option), style: AppTextStyles.body),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
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

// ---------------------------------------------------------------------------
// Grupos iOS
// ---------------------------------------------------------------------------

/// Etiqueta de sección (`SERVICIOS`, `REPRODUCCIÓN`, …).
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Contenedor de filas (`#1c1c1e`, radio 13).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: BorderRadius.all(Radius.circular(13)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Intercala separadores inset (54px) entre filas de un grupo.
List<Widget> _withSeparators(List<Widget> rows) {
  return [
    for (var i = 0; i < rows.length; i++) ...[
      if (i > 0) const Divider(indent: 54),
      rows[i],
    ],
  ];
}

/// Fila de ajustes: badge de color + etiqueta + valor/chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.badge,
    required this.label,
    this.value,
    this.chevron = false,
    this.onTap,
  });

  final IconData icon;
  final Color badge;
  final String label;
  final String? value;
  final bool chevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: badge,
                  borderRadius: BorderRadius.circular(7.5),
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (chevron) ...[
                const SizedBox(width: 6),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de los servicios del backend (`GET /api/health`)
// ---------------------------------------------------------------------------

class _ServicesStatus extends ConsumerWidget {
  const _ServicesStatus();

  static const List<Color> _badges = [
    Color(0xFF34C759),
    Color(0xFF0A84FF),
    Color(0xFFFF9F0A),
    Color(0xFF5E5CE6),
    Color(0xFFFF375F),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);
    return health.when(
      loading: () => const _PlainRow(
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Consultando el estado…', style: AppTextStyles.cardSubtitle),
          ],
        ),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSeparators([
          const _SettingsRow(
            icon: LucideIcons.alertTriangle,
            badge: Color(0xFFFF453A),
            label: 'No se pudo consultar el estado del backend.',
          ),
          _SettingsRow(
            icon: LucideIcons.refreshCw,
            badge: const Color(0xFF0A84FF),
            label: 'Reintentar',
            onTap: () => ref.invalidate(apiHealthProvider),
          ),
        ]),
      ),
      data: (status) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _withSeparators([
          _SettingsRow(
            icon: status.ok ? LucideIcons.check : LucideIcons.alertTriangle,
            badge: status.ok
                ? const Color(0xFF34C759)
                : const Color(0xFFFF453A),
            label: status.summary,
            value: status.uptimeSeconds != null
                ? 'Uptime ${_formatUptime(status.uptimeSeconds!)}'
                : null,
          ),
          for (var i = 0; i < status.services.length; i++)
            _SettingsRow(
              icon: status.services[i].ok
                  ? LucideIcons.check
                  : LucideIcons.x,
              badge: _badges[i % _badges.length],
              label: status.services[i].name,
              value: [
                if (status.services[i].detail != null)
                  status.services[i].detail!,
                if (status.services[i].latencyMs != null)
                  '${status.services[i].latencyMs!.round()} ms',
              ].join(' · '),
            ),
          _SettingsRow(
            icon: LucideIcons.refreshCw,
            badge: const Color(0xFF0A84FF),
            label: 'Actualizar estado',
            onTap: () => ref.invalidate(apiHealthProvider),
          ),
        ]),
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

/// Fila simple sin badge (loading).
class _PlainRow extends StatelessWidget {
  const _PlainRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: child,
    );
  }
}
