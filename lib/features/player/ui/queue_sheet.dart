import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_player_card.dart';
import '../providers/player_provider.dart';
import '../providers/queue_provider.dart';

/// Bottom sheet de la cola de reproducción (estilo Glass 1).
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  /// Muestra la hoja de cola.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(queueProvider);
    final player = ref.watch(playerProvider);
    final controller = ref.read(playerProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: GlassPlayerCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                _Handle(),
                Row(
                  children: [
                    const Icon(LucideIcons.listMusic,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Text('En cola', style: AppTextStyles.title),
                    const SizedBox(width: 8),
                    Text('(${queue.tracks.length})',
                        style: AppTextStyles.caption),
                    const Spacer(),
                    if (queue.tracks.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          controller.clearQueue();
                          Navigator.of(context).maybePop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(LucideIcons.trash2, size: 15),
                        label: const Text('Limpiar'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: queue.tracks.isEmpty
                      ? const EmptyState(
                          icon: LucideIcons.listMusic,
                          title: 'La cola está vacía',
                          subtitle: 'Agregá canciones desde cualquier lista.',
                        )
                      : ReorderableListView.builder(
                          scrollController: scrollController,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: queue.tracks.length,
                          // onReorderItem ya entrega el índice final ajustado.
                          onReorderItem: (oldIndex, newIndex) {
                            ref
                                .read(queueProvider.notifier)
                                .reorder(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final track = queue.tracks[index];
                            final isActive =
                                index == queue.currentIndex && player.hasTrack;
                            return _QueueTile(
                              key: ValueKey(
                                  '${track.trackId}_$index'),
                              index: index,
                              title: track.displayTitle,
                              subtitle: track.artist ?? '',
                              duration: track.duration,
                              isActive: isActive,
                              isPlaying: isActive && player.playing,
                              onTap: () =>
                                  ref.read(queueProvider.notifier).jumpTo(index),
                              onRemove: () =>
                                  ref.read(queueProvider.notifier).removeAt(index),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.isActive,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final String title;
  final String subtitle;
  final Duration duration;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.accent.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(LucideIcons.gripVertical,
                    size: 16, color: AppColors.textTertiary),
              ),
              SizedBox(
                width: 22,
                child: Center(
                  child: Text('${index + 1}', style: AppTextStyles.caption),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(color: color),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  isPlaying ? LucideIcons.barChart3 : LucideIcons.waves,
                  size: 16,
                  color: AppColors.accent,
                ),
              const SizedBox(width: 4),
              Text(DurationFormatter.format(duration),
                  style: AppTextStyles.caption),
              IconButton(
                tooltip: 'Quitar',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(LucideIcons.x,
                    size: 16, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
