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
import '../../../services/api/health_service.dart';
import '../providers/settings_provider.dart';

/// Ajustes: servidor, token, calidad de audio, caché y acerca de.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _url;
  late final TextEditingController _token;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _url = TextEditingController(text: settings.baseUrl);
    _token = TextEditingController(text: settings.apiToken);
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final test = ref.watch(connectionTestProvider);

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 180),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 16),
          child: Text('Ajustes', style: AppTextStyles.headline),
        ),

        // --- Servidor ---
        _Section(
          title: 'Servidor',
          icon: LucideIcons.cloud,
          children: [
            _LabeledField(
              label: 'URL del backend',
              controller: _url,
              hint: ApiConstants.baseUrl,
              keyboardType: TextInputType.url,
              trailing: IconButton(
                tooltip: 'Restaurar por defecto',
                onPressed: () {
                  _url.text = ApiConstants.baseUrl;
                  controller.resetBaseUrl();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 16),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _save(controller),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(LucideIcons.check, size: 16),
                    label: const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        (test?.isLoading ?? false) ? null : _testConnection,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: (test?.isLoading ?? false)
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.activity, size: 16),
                    label: const Text('Probar'),
                  ),
                ),
              ],
            ),
            if (test != null) ...[
              const SizedBox(height: 12),
              _ConnectionResult(state: test),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // --- Token ---
        _Section(
          title: 'Token de acceso',
          icon: LucideIcons.lock,
          children: [
            _LabeledField(
              label: 'Bearer token',
              controller: _token,
              hint: 'Token de la API',
              obscureText: _obscureToken,
              trailing: IconButton(
                tooltip: _obscureToken ? 'Mostrar' : 'Ocultar',
                onPressed: () =>
                    setState(() => _obscureToken = !_obscureToken),
                icon: Icon(
                  _obscureToken ? LucideIcons.search : LucideIcons.check,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  settings.hasCustomToken
                      ? 'Token personalizado'
                      : 'Token por defecto precargado',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _token.text = ApiConstants.defaultApiToken;
                    controller.resetToken();
                  },
                  child: const Text('Restaurar'),
                ),
              ],
            ),
          ],
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
                  child: Text('Oscuro siempre activo', style: AppTextStyles.body),
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

  Future<void> _save(SettingsController controller) async {
    try {
      await controller.setBaseUrl(_url.text);
      await controller.setApiToken(_token.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar')),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    ref.read(connectionTestProvider.notifier).state = const AsyncValue.loading();
    try {
      final status = await ref.read(settingsProvider.notifier).testConnection();
      ref.read(connectionTestProvider.notifier).state = AsyncValue.data(status);
    } catch (error, stack) {
      ref.read(connectionTestProvider.notifier).state =
          AsyncValue.error(error, stack);
    }
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

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: false,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: trailing,
          ),
        ),
      ],
    );
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
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionResult extends StatelessWidget {
  const _ConnectionResult({required this.state});

  final AsyncValue<HealthStatus> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Probando conexión…', style: AppTextStyles.caption),
        ],
      ),
      data: (value) => _ResultRow(
        icon: LucideIcons.check,
        color: AppColors.accent,
        text: value.summary,
      ),
      error: (error, _) => _ResultRow(
        icon: LucideIcons.alertTriangle,
        color: AppColors.danger,
        text: 'No se pudo conectar: $error',
      ),
    );
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
