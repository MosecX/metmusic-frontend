import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_player_card.dart';
import '../../../navigation/routes.dart';
import '../providers/player_provider.dart';
import 'player_artwork.dart';

/// Minireproductor persistente (estilo Glass 1) sobre la bottom nav.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    if (!state.hasTrack) return const SizedBox.shrink();

    final controller = ref.read(playerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GlassPlayerCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => context.push(Routes.player),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: AppConstants.miniPlayerHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      PlayerArtwork(
                        url: state.artworkUrl,
                        size: 44,
                        heroTag: AppConstants.heroArtworkTag,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      if (state.loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          tooltip: state.playing ? 'Pausar' : 'Reproducir',
                          onPressed: controller.togglePlayPause,
                          icon: Icon(
                            state.playing ? LucideIcons.pause : LucideIcons.play,
                            size: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Siguiente',
                        onPressed: controller.next,
                        icon: const Icon(
                          LucideIcons.skipForward,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic);
  }
}
