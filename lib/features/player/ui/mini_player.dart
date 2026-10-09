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
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                      child: Row(
                    children: [
                      PlayerArtwork(
                        url: state.artworkUrl,
                        size: 46,
                        radius: 10,
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
                              style: AppTextStyles.body.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              state.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
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
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            tooltip: state.playing ? 'Pausar' : 'Reproducir',
                            padding: EdgeInsets.zero,
                            onPressed: controller.togglePlayPause,
                            icon: Icon(
                              state.playing
                                  ? LucideIcons.pause
                                  : LucideIcons.play,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          tooltip: 'Siguiente',
                          padding: EdgeInsets.zero,
                          onPressed: controller.next,
                          icon: const Icon(
                            LucideIcons.skipForward,
                            size: 21,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                        ],
                      ),
                    ),
                    // Progreso: barrita fina insetada (boceto: inset 14, alto 2.5).
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                    ),
                  ],
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
