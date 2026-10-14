import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/radio_mix.dart';
import '../../../core/models/track.dart';
import '../../../core/models/track_details.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../navigation/routes.dart';
import '../../../services/service_providers.dart';
import '../providers/radio_provider.dart';

/// Acciones disponibles en el menú de contexto de una pista.
///
/// Para agregar una: sumar el caso acá, en [TrackContextMenu._buildItem] y
/// en el `switch` de [openTrackContextMenu].
enum TrackAction {
  /// Estación: reproduce la mezcla y abre su página (`/mix/{trackId}`).
  radio,

  /// Navega al detalle del álbum.
  album,

  /// Navega al detalle del artista.
  artist,

  /// Abre el modal con el TrackSchema completo.
  metadata,
}

/// Abre el menú de contexto de [track] y ejecuta la acción elegida.
///
/// Sólo ofrece el álbum/artista si la pista trae el id correspondiente.
Future<void> openTrackContextMenu(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final albumId = track.albumId;
  final artistId = track.artistId;
  final actions = <TrackAction>[
    if (!ref.read(radioUnsupportedProvider).contains(track.trackId))
      TrackAction.radio,
    if (albumId != null && albumId.isNotEmpty) TrackAction.album,
    if (artistId != null && artistId.isNotEmpty) TrackAction.artist,
    TrackAction.metadata,
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
    case TrackAction.album:
      unawaited(context.push(Routes.albumPath(albumId!)));
    case TrackAction.artist:
      unawaited(context.push(Routes.artistPath(artistId!)));
    case TrackAction.metadata:
      await _showMetadata(context, ref, track);
  }
}

/// Pide la estación de [track] y abre su página (`/mix/{trackId}`) sin
/// arrancar la reproducción: el usuario decide desde ahí.
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
      message: 'Abriendo la estación…',
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
  unawaited(context.push(Routes.mixPath(track.trackId)));
}

/// Carga el TrackSchema completo de la pista y abre el modal con sus
/// metadatos.
Future<void> _showMetadata(
  BuildContext context,
  WidgetRef ref,
  Track track,
) async {
  final TrackDetails details;
  try {
    details = await LoadingOverlay.show<TrackDetails>(
      context,
      ref.read(trackServiceProvider).getTrackDetails(track.trackId),
      message: 'Cargando metadatos…',
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
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => TrackDetailsSheet(details: details),
  );
}

/// Hoja con las acciones de una pista (la lista la decide
/// [openTrackContextMenu]).
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
        // La hoja modal sin `isScrollControlled` se limita a 9/16 de la
        // pantalla: con tipografía grande o en pantallas bajas la columna
        // desbordaba y el ClipRRect de GlassCard se comía el último ítem
        // (Metadatos). Con shrinkWrap la lista abraza el contenido y, si
        // no entra, scrollea.
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: _Cover(track: track),
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
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, TrackAction action) {
    switch (action) {
      case TrackAction.radio:
        return ListTile(
          leading: const Icon(LucideIcons.radio, size: 18),
          title: Text('Estación: ${track.displayTitle}'),
          subtitle: const Text(
            'Reproduce la mezcla y abre su página',
            style: AppTextStyles.caption,
          ),
          onTap: () => Navigator.of(context).pop(action),
        );
      case TrackAction.album:
        return ListTile(
          leading: const Icon(LucideIcons.album, size: 18),
          title: const Text('Ir al álbum'),
          subtitle: track.album == null
              ? null
              : Text(
                  track.album!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
          onTap: () => Navigator.of(context).pop(action),
        );
      case TrackAction.artist:
        return ListTile(
          leading: const Icon(LucideIcons.userRound, size: 18),
          title: const Text('Ir al artista'),
          onTap: () => Navigator.of(context).pop(action),
        );
      case TrackAction.metadata:
        return ListTile(
          leading: const Icon(LucideIcons.info, size: 18),
          title: const Text('Metadatos'),
          subtitle: const Text(
            'ISRC, BPM, calidad, copyright…',
            style: AppTextStyles.caption,
          ),
          onTap: () => Navigator.of(context).pop(action),
        );
    }
  }
}

/// Portada de la pista en el encabezado del menú (con fallback a la nota
/// musical si no hay miniatura).
class _Cover extends StatelessWidget {
  const _Cover({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(
      LucideIcons.music,
      size: 24,
      color: AppColors.textSecondary,
    );
    final url = track.listThumbnailUrl;
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        placeholder: (_, __) => const ColoredBox(
          color: AppColors.backgroundAlt,
          child: SizedBox.expand(),
        ),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Modal con el TrackSchema completo de una pista
/// (`GET /api/tracks/{trackId}`).
class TrackDetailsSheet extends StatelessWidget {
  const TrackDetailsSheet({super.key, required this.details});

  final TrackDetails details;

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Mismo motivo que en el menú: con 14 filas la hoja desborda el
        // tope de 9/16 y sin scroll la mitad de los metadatos quedaba
        // fuera de pantalla.
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    leading: Icon(LucideIcons.info, size: 20),
                    title: Text('Metadatos', style: AppTextStyles.title),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.title,
                          style: AppTextStyles.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (details.artist != null)
                          Text(
                            details.artist!,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  for (final row in rows)
                    _DetailRow(label: row.label, value: row.value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<({String label, String value})> _rows() {
    final d = details;
    return [
      (label: 'Álbum', value: d.album ?? '—'),
      (
        label: 'Duración',
        value: DurationFormatter.fromSeconds(d.durationSeconds)
      ),
      (label: 'Calidad', value: d.quality ?? '—'),
      if (d.version != null) (label: 'Versión', value: d.version!),
      (label: 'Explícito', value: d.explicit ? 'Sí' : 'No'),
      (label: 'ISRC', value: d.isrc ?? '—'),
      if (d.bpm != null) (label: 'BPM', value: _num(d.bpm!)),
      if (d.peak != null) (label: 'Pico (dB)', value: _num(d.peak!)),
      if (d.popularity != null)
        (label: 'Popularidad', value: _num(d.popularity!)),
      if (d.copyright != null) (label: 'Copyright', value: d.copyright!),
      (label: 'Stream listo', value: d.streamReady ? 'Sí' : 'No'),
      (label: 'ID de pista', value: d.trackId),
      if (d.artistId != null) (label: 'ID de artista', value: d.artistId!),
      if (d.albumId != null) (label: 'ID de álbum', value: d.albumId!),
    ];
  }

  /// `65.2` / `123`: sin ceros de más.
  static String _num(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
