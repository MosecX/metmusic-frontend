import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/album.dart';
import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../providers/album_provider.dart';

/// Detalle de álbum (`GET /api/albums/{albumId}`).
class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = ref.watch(albumDetailProvider(albumId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: album.when(
        loading: () => const _Loading(),
        error: (error, _) => Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassBackButton(onTap: () => Navigator.of(context).maybePop()),
                  ),
                  Expanded(
                    child: ErrorState(
                      error: error,
                      onRetry: () => ref.invalidate(albumDetailProvider(albumId)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (data) => _Content(album: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = album.tracks;
    final totalDuration = DurationFormatter.total(
      tracks.map((t) => t.duration),
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: const GlassBackButton(),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: CollapsibleHeader(
              imageUrl: album.thumbnailUrl,
              title: album.title,
              meta: 'Álbum',
              subtitle: [
                if (album.artist != null) album.artist!,
                if (album.year.isNotEmpty) album.year,
                '${album.trackCount} canciones',
                if (totalDuration > Duration.zero)
                  DurationFormatter.long(totalDuration),
              ].join(' • '),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _PlayAllButton(
                    label: 'Reproducir todo',
                    icon: LucideIcons.play,
                    filled: true,
                    onTap: tracks.isEmpty
                        ? null
                        : () => ref.playAll(tracks),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlayAllButton(
                    label: 'Aleatorio',
                    icon: LucideIcons.shuffle,
                    filled: false,
                    onTap: tracks.isEmpty
                        ? null
                        : () => ref.playAll(tracks, shuffled: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tracks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Este álbum no tiene tracks disponibles.',
                  style: AppTextStyles.subtitle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < tracks.length; i++)
                      _AlbumTrackRow(
                        track: tracks[i],
                        index: i + 1,
                        context_: tracks,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AlbumTrackRow extends ConsumerWidget {
  const _AlbumTrackRow({
    required this.track,
    required this.index,
    required this.context_,
  });

  final Track track;
  final int index;
  final List<Track> context_;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final isActive = state.track?.trackId == track.trackId;

    return TrackRow(
      track: track,
      showArtwork: false,
      index: index,
      isActive: isActive,
      isPlaying: state.playing,
      onTap: () => ref.playTrack(track, context: context_, index: index - 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(LucideIcons.barChart3,
                  size: 14, color: AppColors.accent),
            ),
          IconButton(
            tooltip: 'Agregar a la cola',
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.enqueueTrack(track),
            icon: const Icon(LucideIcons.plus,
                size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  const _PlayAllButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: filled ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
      foregroundColor: filled ? Colors.black : AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    return FilledButton.icon(
      onPressed: onTap,
      style: style,
      icon: Icon(icon, size: 18),
      label: Text(label, style: AppTextStyles.button.copyWith(
        color: filled ? Colors.black : AppColors.textPrimary,
      )),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const _Background(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ShimmerBox(height: 220, borderRadius: 20),
              SizedBox(height: 20),
              ShimmerTrackList(count: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: child,
    );
  }
}
