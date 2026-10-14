import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/album.dart';
import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/main_shell.dart';
import '../../../navigation/routes.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../../player/ui/track_context_menu.dart';
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
      extendBody: true,
      bottomNavigationBar: const GlobalMiniPlayer(),
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
                    child: GlassBackButton(
                        onTap: () => Navigator.of(context).maybePop()),
                  ),
                  Expanded(
                    child: ErrorState(
                      error: error,
                      onRetry: () =>
                          ref.invalidate(albumDetailProvider(albumId)),
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
        const SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: GlassBackButton(),
          centerTitle: true,
          title: Text(
            'Álbum',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailHeader(
            imageUrl: album.thumbnailUrl,
            title: album.title,
            artist: album.artist,
            onArtistTap: (album.artistId != null && album.artistId!.isNotEmpty)
                ? () => context.push(Routes.artistPath(album.artistId!))
                : null,
            meta: [
              if (album.year.isNotEmpty) album.year,
              '${album.trackCount} canciones',
              if (totalDuration > Duration.zero)
                DurationFormatter.long(totalDuration),
            ].join(' • '),
            actionsEnabled: tracks.isNotEmpty,
            onShuffle: tracks.isEmpty
                ? null
                : () => ref.playAll(tracks, shuffled: true),
            onPlay: tracks.isEmpty ? null : () => ref.playAll(tracks),
            onMore: tracks.isEmpty ? null : () => _showMore(context, ref),
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
      ],
    );
  }

  Future<void> _showMore(BuildContext context, WidgetRef ref) {
    final tracks = album.tracks;
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
