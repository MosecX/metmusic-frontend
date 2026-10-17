import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/content_width.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/main_shell.dart';
import '../../library/providers/library_provider.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../../player/ui/track_context_menu.dart';
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
      extendBody: true,
      bottomNavigationBar: const GlobalMiniPlayer(),
      body: ContentWidth(
        child: async.when(
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
          pinned: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: const GlassBackButton(),
          centerTitle: true,
          title: Text(
            view.meta,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailHeader(
            imageUrl: view.imageUrl,
            title: view.title,
            artist: (view.subtitle != null && view.subtitle!.isNotEmpty)
                ? view.subtitle
                : null,
            meta: [
              '${tracks.length} canciones',
              if (total > Duration.zero) DurationFormatter.long(total),
            ].join(' • '),
            actionsEnabled: tracks.isNotEmpty,
            onShuffle: tracks.isEmpty
                ? null
                : () => ref.playAll(tracks, shuffled: true),
            onPlay: tracks.isEmpty ? null : () => ref.playAll(tracks),
            onMore: tracks.isEmpty ? null : () => _showMore(context, ref),
          ),
        ),
        if (view.description != null && view.description!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Text(
                view.description!,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLight,
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
      ],
    );
  }

  Future<void> _showMore(BuildContext context, WidgetRef ref) {
    final tracks = view.tracks;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(LucideIcons.shuffle, color: AppColors.textPrimary),
              title: const Text('Reproducir aleatorio'),
              onTap: () {
                Navigator.of(context).pop();
                ref.playAll(tracks, shuffled: true);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.listPlus,
                  color: AppColors.textPrimary),
              title: const Text('Agregar todas a la cola'),
              onTap: () {
                Navigator.of(context).pop();
                for (final track in tracks) {
                  unawaited(ref.enqueueTrack(track));
                }
              },
            ),
          ],
        ),
      ),
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
    final (isActive, playing) = ref.watch(
      playerProvider.select(
        (s) => (s.track?.trackId == track.trackId, s.playing),
      ),
    );

    return TrackRow(
      track: track,
      index: index,
      showArtwork: false,
      showAlbum: true,
      isActive: isActive,
      isPlaying: playing,
      onTap: () => ref.playTrack(track, context: queue, index: index - 1),
      onLongPress: () => openTrackContextMenu(context, ref, track),
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
