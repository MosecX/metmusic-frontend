import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/radio_mix.dart';
import '../../../core/models/track.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../services/service_providers.dart';
import '../providers/playback_actions.dart';
import '../providers/radio_provider.dart';

/// Acciones disponibles en el menú de contexto de una pista.
///
/// Para agregar una: sumar el caso acá, en [_TrackContextMenu._buildItem]
/// y en el `switch` de [openTrackContextMenu].
enum TrackAction {
  /// Estación/radio: cola nueva armada a partir de esta pista.
  radio,
}

/// Abre el menú de contexto de [track] y ejecuta la acción elegida.
///
/// No abre nada si la pista no tiene ninguna acción disponible (hoy sólo
/// aplica a pistas sin radio, ver [radioUnsupportedProvider]).
Future<void> openTrackContextMenu(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final actions = <TrackAction>[
    if (!ref.read(radioUnsupportedProvider).contains(track.trackId))
      TrackAction.radio,
  ];
  if (actions.isEmpty) return;

  final selected = await showModalBottomSheet<TrackAction>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => TrackContextMenu(track: track, actions: actions),
  );
  if (selected == null || !context.mounted) return;

  switch (selected) {
    case TrackAction.radio:
      await _startRadio(context, ref, track);
  }
}

/// Pide la estación de [track] y la reproduce como cola nueva.
///
/// En frío tarda ~0.5–1 s (dos peticiones encadenadas + throttle de 300 ms
/// en el backend): se tapa con un overlay de carga y NO se reintenta en
/// bucle. 404 = sin radio: se recuerda para no volver a ofrecerla.
Future<void> _startRadio(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  RadioStation? station;
  try {
    station = await LoadingOverlay.show<RadioStation?>(
      context,
      ref.read(radioServiceProvider).getRadio(track.trackId),
      message: 'Armando la estación…',
    );
  } on ApiException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
    return;
  }

  if (!context.mounted) return;
  if (station == null) {
    ref.read(radioUnsupportedProvider.notifier).state = {
      ...ref.read(radioUnsupportedProvider),
      track.trackId,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esta pista no tiene estación')),
    );
    return;
  }
  await ref.playAll(station.items);
}

/// Hoja con las acciones de una pista (hoy sólo la estación; la lista la
/// decide [openTrackContextMenu]).
class TrackContextMenu extends StatelessWidget {
  const TrackContextMenu({
    super.key,
    required this.track,
    required this.actions,
  });

  final Track track;
  final List<TrackAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  LucideIcons.music,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                title: Text(
                  track.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
                subtitle: Text(
                  track.artist ?? 'Desconocido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
              const Divider(height: 1),
              for (final action in actions) _buildItem(context, action),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, TrackAction action) {
    switch (action) {
      case TrackAction.radio:
        return ListTile(
          leading: const Icon(LucideIcons.radio, size: 18),
          title: Text(
            track.artist == null
                ? 'Radio'
                : 'Estación de ${track.artist}',
          ),
          subtitle: const Text(
            'Mezcla de pistas parecidas',
            style: AppTextStyles.caption,
          ),
          onTap: () => Navigator.of(context).pop(action),
        );
    }
  }
}
