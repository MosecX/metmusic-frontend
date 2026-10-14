import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/artist.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/album_card.dart';
import '../../../core/widgets/collapsible_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/main_shell.dart';
import '../../../navigation/routes.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../../player/ui/track_context_menu.dart';
import '../providers/artist_provider.dart';

/// Detalle de artista (`GET /api/artists/{artistId}`).
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.artistId});

  final String artistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artist = ref.watch(artistDetailProvider(artistId));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: const GlobalMiniPlayer(),
      body: artist.when(
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
                      onRetry: () =>
                          ref.invalidate(artistDetailProvider(artistId)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (data) => _Content(artist: data),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.artist});

  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topTracks = artist.topTracks;
    final playerState = ref.watch(playerProvider);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: GlassBackButton(),
          centerTitle: true,
          title: Text(
            'Artista',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        SliverToBoxAdapter(
          child: DetailHeader(
            imageUrl: artist.imageUrl,
            title: artist.name,
            isRound: true,
            meta: [
              if (artist.albums.isNotEmpty) '${artist.albums.length} álbumes',
              if (topTracks.isNotEmpty) '${topTracks.length} canciones',
            ].join(' • '),
            actionsEnabled: topTracks.isNotEmpty,
            onShuffle: topTracks.isEmpty
                ? null
                : () => ref.playAll(topTracks, shuffled: true),
            onPlay: topTracks.isEmpty ? null : () => ref.playAll(topTracks),
          ),
        ),
        if (artist.bio != null && artist.bio!.trim().isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Text(
                artist.bio!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLight,
              ),
            ),
          ),
        if (topTracks.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Populares'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (var i = 0; i < topTracks.length; i++)
                        TrackRow(
                          track: topTracks[i],
                          index: i + 1,
                          showArtwork: false,
                          showAlbum: true,
                          isActive: playerState.track?.trackId ==
                              topTracks[i].trackId,
                          isPlaying: playerState.playing,
                          onTap: () => ref.playTrack(
                            topTracks[i],
                            context: topTracks,
                            index: i,
                          ),
                          onLongPress: () =>
                              openTrackContextMenu(context, ref, topTracks[i]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (artist.albums.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Álbumes'),
                SizedBox(
                  height: 216,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: artist.albums.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) => AlbumCard(
                      album: artist.albums[index],
                      onTap: () => context
                          .push(Routes.albumPath(artist.albums[index].albumId)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 160)),
      ],
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
              ShimmerBox(height: 200, borderRadius: 20),
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
