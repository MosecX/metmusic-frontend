import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/radio_mix.dart';
import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/main_shell.dart';
import '../providers/playback_actions.dart';
import '../providers/player_provider.dart';
import '../providers/radio_provider.dart';
import 'track_context_menu.dart';

/// Página de una estación (`/mix/:trackId`): su portada, su título y todas
/// sus pistas listas para reproducir. Se abre desde el menú de contexto,
/// que además arranca la reproducción.
class MixScreen extends ConsumerWidget {
  const MixScreen({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(mixDetailProvider(trackId));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: const GlobalMiniPlayer(),
      body: station.when(
        loading: () => const _Loading(),
        error: (error, _) => Stack(
          children: [
            const _Background(),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassBackButton(
                        onTap: () => Navigator.of(context).maybePop()),
                  ),
                  Expanded(
                    child: ErrorState(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(mixDetailProvider(trackId)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (data) => _Content(station: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.station});

  final RadioStation station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = station.items;
    final totalDuration =
        DurationFormatter.total(tracks.map((t) => t.duration));
    final seed = tracks.isEmpty ? null : tracks.first;
    final description = station.mix.description;

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
              imageUrl: station.mix.imageUrl ?? seed?.listThumbnailUrl ?? '',
              title: station.mix.title,
              meta: 'Estación',
              subtitle: [
                if (station.mix.subTitle?.isNotEmpty ?? false)
                  station.mix.subTitle!,
                '${tracks.length} pistas',
                if (totalDuration > Duration.zero)
                  DurationFormatter.long(totalDuration),
              ].join(' • '),
            ),
          ),
        ),
        if (description != null && description.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                description,
                style: AppTextStyles.bodyLight
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _MixActionButton(
                    label: 'Reproducir todo',
                    icon: LucideIcons.play,
                    filled: true,
                    onTap: tracks.isEmpty ? null : () => ref.playAll(tracks),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MixActionButton(
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
                  'La estación no trae pistas.',
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
                      _MixTrackRow(
                        track: tracks[i],
                        index: i + 1,
                        queue: tracks,
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

class _MixTrackRow extends ConsumerWidget {
  const _MixTrackRow({
    required this.track,
    required this.index,
    required this.queue,
  });

  final Track track;
  final int index;
  final List<Track> queue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final isActive = state.track?.trackId == track.trackId;

    return TrackRow(
      track: track,
      showArtwork: false,
      showAlbum: true,
      index: index,
      isActive: isActive,
      isPlaying: state.playing,
      onTap: () => ref.playTrack(track, context: queue, index: index - 1),
      onLongPress: () => openTrackContextMenu(context, ref, track),
      trailing: IconButton(
        tooltip: 'Agregar a la cola',
        visualDensity: VisualDensity.compact,
        onPressed: () => ref.enqueueTrack(track),
        icon: const Icon(LucideIcons.plus,
            size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MixActionButton extends StatelessWidget {
  const _MixActionButton({
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
    return FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor:
            filled ? AppColors.accent : Colors.white.withValues(alpha: 0.08),
        foregroundColor: filled ? Colors.black : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: AppTextStyles.button.copyWith(
          color: filled ? Colors.black : AppColors.textPrimary,
        ),
      ),
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
