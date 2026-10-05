import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../library/providers/library_provider.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../providers/playlist_provider.dart';

/// Detalle de playlist (editorial o del usuario).
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.isUserPlaylist = false,
  });

  final String playlistId;
  final bool isUserPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = isUserPlaylist
        ? ref.watch(userPlaylistDetailProvider(playlistId)).whenData(
              (p) => _PlaylistView(
                title: p.name,
                subtitle: p.description,
                imageUrl: p.coverUrl ?? '',
                tracks: p.tracks,
                meta: 'Mi playlist',
                isUserPlaylist: true,
              ),
            )
        : ref.watch(playlistDetailProvider(playlistId)).whenData(
              (p) => _PlaylistView(
                title: p.title,
                subtitle: p.creator,
                imageUrl: p.thumbnailUrl,
                tracks: p.tracks,
                meta: 'Playlist',
                description: p.description,
              ),
            );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: async.when(
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
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: ErrorState(
                      error: error,
                      onRetry: () => ref.invalidate(
                        isUserPlaylist
                            ? userPlaylistDetailProvider(playlistId)
                            : playlistDetailProvider(playlistId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (view) => _Content(view: view, playlistId: playlistId),
      ),
    );
  }
}

/// Vista normalizada para playlist editorial y de usuario.
class _PlaylistView {
  const _PlaylistView({
    required this.title,
    required this.imageUrl,
    required this.tracks,
    required this.meta,
    this.subtitle,
    this.description,
    this.isUserPlaylist = false,
  });

  final String title;
  final String imageUrl;
  final List<Track> tracks;
  final String meta;
  final String? subtitle;
  final String? description;
  final bool isUserPlaylist;
}

class _Content extends ConsumerWidget {
  const _Content({required this.view, required this.playlistId});

  final _PlaylistView view;
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = view.tracks;
    final total = DurationFormatter.total(tracks.map((t) => t.duration));

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
              imageUrl: view.imageUrl,
              title: view.title,
              meta: view.meta,
              subtitle: [
                if (view.subtitle != null && view.subtitle!.isNotEmpty)
                  view.subtitle!,
                '${tracks.length} canciones',
                if (total > Duration.zero) DurationFormatter.long(total),
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
                  child: FilledButton.icon(
                    onPressed: tracks.isEmpty ? null : () => ref.playAll(tracks),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(LucideIcons.play, size: 18),
                    label: const Text('Reproducir todo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: tracks.isEmpty
                        ? null
                        : () => ref.playAll(tracks, shuffled: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(LucideIcons.shuffle, size: 18),
                    label: const Text('Aleatorio'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (view.description != null && view.description!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  view.description!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLight,
                ),
              ),
            ),
          ),
        if (tracks.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: LucideIcons.listMusic,
                title: 'Playlist vacía',
                subtitle: 'Todavía no hay canciones acá.',
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
                      _PlaylistTrackRow(
                        track: tracks[i],
                        index: i + 1,
                        queue: tracks,
                        canRemove: view.isUserPlaylist,
                        onRemove: () => ref
                            .read(userPlaylistsProvider.notifier)
                            .removeTrack(playlistId, tracks[i].trackId),
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

class _PlaylistTrackRow extends ConsumerWidget {
  const _PlaylistTrackRow({
    required this.track,
    required this.index,
    required this.queue,
    required this.canRemove,
    required this.onRemove,
  });

  final Track track;
  final int index;
  final List<Track> queue;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerProvider);
    final isActive = state.track?.trackId == track.trackId;

    return TrackRow(
      track: track,
      index: index,
      showArtwork: false,
      showAlbum: true,
      isActive: isActive,
      isPlaying: state.playing,
      onTap: () => ref.playTrack(track, context: queue, index: index - 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Agregar a la cola',
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.enqueueTrack(track),
            icon: const Icon(LucideIcons.plus,
                size: 16, color: AppColors.textSecondary),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'Quitar de la playlist',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(LucideIcons.x,
                  size: 16, color: AppColors.textTertiary),
            ),
        ],
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
              ShimmerTrackList(count: 7),
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
