import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_player_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../library/models/library_models.dart';
import '../../library/providers/library_provider.dart';

/// Bottom sheet para agregar un track a una playlist del usuario.
class AddToPlaylistSheet extends ConsumerWidget {
  const AddToPlaylistSheet({super.key, required this.trackId});

  final String trackId;

  static Future<void> show(BuildContext context, String trackId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => AddToPlaylistSheet(trackId: trackId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(userPlaylistsProvider);

    return ContentWidth(
      maxWidth: AppConstants.readingMaxWidth,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 12,
        ),
        child: GlassPlayerCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.listMusic,
                        size: 18, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text('Agregar a playlist', style: AppTextStyles.title),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: playlists.when(
                    data: (items) => items.isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const EmptyState(
                                icon: LucideIcons.listMusic,
                                title: 'Todavía no tenés playlists',
                                subtitle: 'Creá una desde la Biblioteca.',
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _createAndAdd(context, ref),
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Crear playlist'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final playlist = items[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(LucideIcons.listMusic,
                                    color: AppColors.textSecondary),
                                title: Text(playlist.name),
                                subtitle: Text(
                                  '${playlist.numberOfTracks} canciones',
                                  style: AppTextStyles.caption,
                                ),
                                onTap: () => _add(context, ref, playlist.id),
                              );
                            },
                          ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: ShimmerTrackList(count: 3),
                    ),
                    error: (error, _) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No se pudieron cargar las playlists',
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (playlists.valueOrNull?.isNotEmpty ?? false)
                  TextButton.icon(
                    onPressed: () => _createAndAdd(context, ref),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Nueva playlist'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(
      BuildContext context, WidgetRef ref, String playlistId) async {
    try {
      await LoadingOverlay.show(
        context,
        ref
            .read(userPlaylistsProvider.notifier)
            .addTracks(playlistId, [trackId]),
        message: 'Agregando…',
      );
      if (context.mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track agregado a la playlist')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar el track')),
        );
      }
    }
  }

  Future<void> _createAndAdd(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context);
    if (name == null || name.trim().isEmpty) return;
    if (!context.mounted) return;
    try {
      final created = await ref
          .read(userPlaylistsProvider.notifier)
          .create(CreatePlaylistDraft(name: name.trim()));
      await ref
          .read(userPlaylistsProvider.notifier)
          .addTracks(created.id, [trackId]);
      if (context.mounted) {
        Navigator.of(context).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Agregado a "${created.name}"')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la playlist')),
        );
      }
    }
  }

  Future<String?> _promptName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
