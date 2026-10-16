import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../services/api/health_service.dart';
import '../providers/settings_provider.dart';

/// Ajustes en paneles glass: servicios, reproducción, apariencia y acerca de.
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
          padding: EdgeInsets.only(top: 16, bottom: 6),
          child: Text('Ajustes', style: AppTextStyles.largeTitle),
        ),

        // --- Estado del servidor ---
        const _ServicesSection(),

        // --- Reproducción ---
        const _GroupLabel('Reproducción'),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSeparators([
              _GlassRow(
                icon: LucideIcons.volume2,
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
            ]),
          ),
        ),

        // --- Apariencia ---
        const _GroupLabel('Apariencia'),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSeparators([
              const _GlassRow(
                icon: LucideIcons.moon,
                label: 'Tema',
                value: 'Oscuro',
              ),
              _GlassRow(
                icon: LucideIcons.trash2,
                label: 'Limpiar caché del servidor',
                onTap: () => _clearCache(controller),
              ),
            ]),
          ),
        ),

        // --- Acerca de ---
        const _GroupLabel('Acerca de'),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withSeparators([
              const _GlassRow(
                icon: LucideIcons.info,
                label: 'Aplicación',
                value: AppConstants.appName,
              ),
              const _GlassRow(
                icon: LucideIcons.gitBranch,
                label: 'Versión',
                value: AppConstants.appVersion,
              ),
              _GlassRow(
                icon: LucideIcons.server,
                label: 'Backend',
                value: settings.baseUrl.replaceFirst('https://', ''),
              ),
            ]),
          ),
        ),

        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
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
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassOptionSheet<T>(
        title: title,
        options: options,
        labelOf: labelOf,
        current: current,
        onPick: onPick,
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
// Etiquetas de sección y separadores
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

/// Intercala separadores inset (54px) entre filas de un grupo.
List<Widget> _withSeparators(List<Widget> rows) {
  return [
    for (var i = 0; i < rows.length; i++) ...[
      if (i > 0) const Divider(indent: 54),
      rows[i],
    ],
  ];
}

// ---------------------------------------------------------------------------
// Fila glass
// ---------------------------------------------------------------------------

/// Fila de ajustes dentro de un panel glass: chip de icono sutil + etiqueta
/// + valor/chevron. Sin colores estridentes; el estado se comunica con un
/// punto de 8px.
class _GlassRow extends StatelessWidget {
  const _GlassRow({
    required this.icon,
    required this.label,
    this.value,
    this.chevron = false,
    this.dotColor,
    this.dotGlow = false,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool chevron;
  final Color? dotColor;
  final bool dotGlow;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 17,
                color: iconColor ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: labelColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (dotColor != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: dotGlow
                      ? [
                          BoxShadow(
                            color: dotColor!.withValues(alpha: 0.55),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
            if (value != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
            if (chevron) ...[
              const SizedBox(width: 6),
              const Icon(
                LucideIcons.chevronRight,
                size: 15,
                color: AppColors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hoja glass de opciones (calidad de audio / letras)
// ---------------------------------------------------------------------------

/// Panel flotante con las opciones de una preferencia: título arriba, filas
/// con check en la selección y "Cancelar" al pie.
class _GlassOptionSheet<T> extends StatelessWidget {
  const _GlassOptionSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.current,
    required this.onPick,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final T current;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            for (final option in options)
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onPick(option);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelOf(option),
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w500,
                            color: option == current
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (option == current)
                        const Icon(LucideIcons.check,
                            size: 18, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            const Divider(height: 1),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado del backend (`GET /api/health`): servidor, metadatos, stream y sistema
// ---------------------------------------------------------------------------

const Color _statusGreen = Color(0xFF34C759);
const Color _statusRed = Color(0xFFFF453A);
const Color _statusGray = Color(0xFF8E8E93);

/// Secciones de estado agrupadas: servidor, metadatos, stream y sistema.
class _ServicesSection extends ConsumerWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(apiHealthProvider);
    final status = health.valueOrNull;

    final services = status?.services ?? const <HealthServiceStatus>[];
    final metadata = services.where(_isMetadata).toList(growable: false);
    final stream = services.where(_isStream).toList(growable: false);
    final system = services
        .where((s) => !_isMetadata(s) && !_isStream(s))
        .toList(growable: false);

    String? serverValue;
    if (status != null) {
      final parts = [
        if (status.version != null) 'v${status.version}',
        if (status.uptimeSeconds != null) _formatUptime(status.uptimeSeconds!),
      ];
      serverValue = parts.isEmpty ? null : parts.join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _GroupLabel('Servidor'),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: status != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _withSeparators([
                    _GlassRow(
                      icon: status.ok
                          ? LucideIcons.check
                          : LucideIcons.alertTriangle,
                      iconColor: status.ok ? null : _statusRed,
                      label:
                          status.ok ? 'Servidor OK' : 'Servidor con problemas',
                      dotColor: status.ok ? _statusGreen : _statusRed,
                      dotGlow: true,
                      value: serverValue,
                    ),
                    _GlassRow(
                      icon: LucideIcons.refreshCw,
                      label: 'Actualizar estado',
                      onTap: () => ref.invalidate(apiHealthProvider),
                    ),
                  ]),
                )
              : health.hasError
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _withSeparators([
                        const _GlassRow(
                          icon: LucideIcons.alertTriangle,
                          iconColor: _statusRed,
                          label: 'No se pudo consultar el estado del backend.',
                        ),
                        _GlassRow(
                          icon: LucideIcons.refreshCw,
                          label: 'Reintentar',
                          onTap: () => ref.invalidate(apiHealthProvider),
                        ),
                      ]),
                    )
                  : const _LoadingRow(),
        ),
        if (metadata.isNotEmpty) ...[
          const _GroupLabel('Metadatos'),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _ServiceRows(services: metadata),
          ),
        ],
        if (stream.isNotEmpty) ...[
          const _GroupLabel('Stream'),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _ServiceRows(services: stream),
          ),
        ],
        if (system.isNotEmpty) ...[
          const _GroupLabel('Sistema'),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _ServiceRows(services: system),
          ),
        ],
      ],
    );
  }
}

/// Filas de servicios de un grupo, con separadores inset.
class _ServiceRows extends StatelessWidget {
  const _ServiceRows({required this.services});

  final List<HealthServiceStatus> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withSeparators([
        for (final service in services) _ServiceRow(service: service),
      ]),
    );
  }
}

/// Fila de un servicio: check verde con glow si está activo, luna gris si
/// está apagado o alerta roja si falló. El texto del `detail` del API no se
/// muestra: el estado se lee con el icono y el punto.
class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service});

  final HealthServiceStatus service;

  @override
  Widget build(BuildContext context) {
    final off = (service.detail ?? '').toLowerCase().contains('apagado');
    final down = !service.ok;

    final IconData icon;
    final Color? iconColor;
    final Color dot;
    final Color? labelColor;
    final String? value;

    if (down) {
      icon = LucideIcons.alertTriangle;
      iconColor = _statusRed;
      dot = _statusRed;
      labelColor = null;
      value = null;
    } else if (off) {
      icon = LucideIcons.moon;
      iconColor = _statusGray;
      dot = _statusGray;
      labelColor = _statusGray;
      value = 'Apagado';
    } else {
      icon = LucideIcons.check;
      iconColor = null;
      dot = _statusGreen;
      labelColor = null;
      final latency = service.latencyMs;
      value = (latency != null && latency > 0) ? '${latency.round()} ms' : null;
    }

    return _GlassRow(
      icon: icon,
      iconColor: iconColor,
      label: service.name,
      labelColor: labelColor,
      dotColor: dot,
      dotGlow: !off,
      value: value,
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}

/// Proveedor de metadatos (catálogo): no entrega audio.
bool _isMetadata(HealthServiceStatus service) {
  return !_isStream(service) &&
      !service.id.toLowerCase().contains('cache') &&
      !service.name.toLowerCase().contains('redis');
}

/// Proveedor de stream: entrega audio (qobuz, tidal, monochrome, jiosaavn…).
bool _isStream(HealthServiceStatus service) {
  final id = service.id.toLowerCase();
  final name = service.name.toLowerCase();
  return id.contains('stream') ||
      name.contains('stream') ||
      const {'qobuz', 'monochrome', 'jiosaavn'}.contains(id);
}

String _formatUptime(double seconds) {
  final total = seconds.toInt();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  if (hours <= 0) return '$minutes min';
  return '$hours h $minutes min';
}
