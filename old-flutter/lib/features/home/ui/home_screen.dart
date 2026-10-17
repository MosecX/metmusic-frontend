import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/album.dart';
import '../../../core/models/artist.dart';
import '../../../core/models/explore.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/album_card.dart';
import '../../../core/widgets/artist_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/playlist_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/routes.dart';
import '../../../services/api/explore_service.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../../player/ui/track_context_menu.dart';
import '../providers/home_provider.dart';

/// Pantalla principal con secciones de exploración.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.backgroundAlt,
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      child: home.when(
        data: (data) => _HomeContent(data: data),
        loading: () => const _HomeSkeleton(),
        error: (error, _) => ListView(
          padding: const EdgeInsets.only(top: 80),
          children: [
            ErrorState(
              error: error,
              onRetry: () => ref.read(homeProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(homeMoodProvider);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.only(top: 12, bottom: AppConstants.shellBottomInset),
      children: [
        _Greeting(),
        const SizedBox(height: 16),
        _MoodChips(
          selected: mood,
          onSelected: (value) {
            ref.read(homeMoodProvider.notifier).state = value;
            ref.read(homeProvider.notifier).setMood(value);
          },
        ),
        const SizedBox(height: 8),
        if (data.offline) const _OfflineBanner(),
        if (data.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: LucideIcons.music,
              title: 'Sin contenido por ahora',
              subtitle: 'Probá cambiar de mood o revisar la conexión.',
            ),
          ),
        if (data.recent.isNotEmpty) ...[
          _RecentSection(entries: data.recent),
          const SizedBox(height: 8),
        ],
        if (data.newReleases.isNotEmpty) ...[
          const SectionHeader(
            title: 'Novedades',
          ),
          _AlbumCarousel(albums: data.newReleases),
          const SizedBox(height: 8),
        ],
        if (data.charts.isNotEmpty) ...[
          const SectionHeader(
            title: 'Top canciones',
          ),
          _TrackListCard(tracks: data.charts, showIndex: true),
          const SizedBox(height: 8),
        ],
        ..._exploreSections(context, ref),
      ],
    );
  }

  List<Widget> _exploreSections(BuildContext context, WidgetRef ref) {
    final widgets = <Widget>[];
    for (final section in data.explore.sections) {
      if (section.isEmpty) continue;
      // Evita duplicar lo ya mostrado arriba.
      if (section.type == ExploreSectionType.albums &&
          section.albums == data.newReleases) {
        continue;
      }
      if (section.type == ExploreSectionType.tracks &&
          section.tracks == data.charts) {
        continue;
      }

      widgets.add(SectionHeader(title: section.title));
      switch (section.type) {
        case ExploreSectionType.albums:
          widgets.add(_AlbumCarousel(albums: section.albums));
          break;
        case ExploreSectionType.tracks:
          widgets.add(_TrackListCard(tracks: section.tracks));
          break;
        case ExploreSectionType.playlists:
          widgets.add(_PlaylistCarousel(playlists: section.playlists));
          break;
        case ExploreSectionType.artists:
          widgets.add(_ArtistCarousel(artists: section.artists));
          break;
        case ExploreSectionType.unknown:
          break;
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final text = switch (hour) {
      >= 6 && < 12 => 'Buenos días',
      >= 12 && < 20 => 'Buenas tardes',
      _ => 'Buenas noches',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.subtitle),
          const SizedBox(height: 4),
          const Text('Inicio', style: AppTextStyles.largeTitle),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}

class _MoodChips extends StatelessWidget {
  const _MoodChips({required this.selected, required this.onSelected});

  final ExploreMood? selected;
  final ValueChanged<ExploreMood?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'Para vos',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final mood in ExploreMood.values)
            _Chip(
              label: mood.label,
              active: selected == mood,
              onTap: () => onSelected(mood),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassCard(
        borderRadius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        fill: active ? Colors.white : AppColors.glassFill,
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: active ? Colors.black : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassCard(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(LucideIcons.wifiOff, size: 16, color: AppColors.warning),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sin conexión: mostrando tu historial local.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Secciones
// ---------------------------------------------------------------------------

class _RecentSection extends ConsumerWidget {
  const _RecentSection({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = entries
        .where((e) => e.track != null)
        .map((e) => e.track!)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recientes'),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _TrackCard(
              track: tracks[index],
              onTap: () =>
                  ref.playTrack(tracks[index], context: tracks, index: index),
              onLongPress: () =>
                  openTrackContextMenu(context, ref, tracks[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card de canción (carrusel "Recientes", estilo boceto: arte 148 + título).
class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final url = track.listThumbnailUrl;
    return SizedBox(
      width: 148,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 148,
                height: 148,
                child: url.isEmpty
                    ? const ArtworkPlaceholder(iconSize: 36)
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        filterQuality: FilterQuality.medium,
                        memCacheWidth: 300,
                        placeholder: (_, __) =>
                            const ArtworkPlaceholder(iconSize: 36),
                        errorWidget: (_, __, ___) =>
                            const ArtworkPlaceholder(iconSize: 36),
                      ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              track.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 2),
            Text(
              track.artist ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCarousel extends ConsumerWidget {
  const _AlbumCarousel({required this.albums});

  final List<Album> albums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final album = albums[index];
          return AlbumCard(
            album: album,
            onTap: () => context.push(Routes.albumPath(album.albumId)),
          );
        },
      ),
    );
  }
}

class _PlaylistCarousel extends StatelessWidget {
  const _PlaylistCarousel({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          return PlaylistCard(
            playlist: playlist,
            onTap: () => context.push(Routes.playlistPath(playlist.playlistId)),
          );
        },
      ),
    );
  }
}

class _ArtistCarousel extends StatelessWidget {
  const _ArtistCarousel({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ArtistCard(
            artist: artist,
            size: 108,
            onTap: () => context.push(Routes.artistPath(artist.artistId)),
          );
        },
      ),
    );
  }
}

class _TrackListCard extends ConsumerWidget {
  const _TrackListCard({required this.tracks, this.showIndex = false});

  final List<Track> tracks;
  final bool showIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (currentId, playing) = ref.watch(
      playerProvider.select((s) => (s.track?.trackId, s.playing)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < tracks.length; i++)
            TrackRow(
              track: tracks[i],
              index: showIndex ? i + 1 : null,
              isActive: tracks[i].trackId == currentId,
              isPlaying: playing,
              onTap: () => ref.playTrack(tracks[i], context: tracks, index: i),
              onLongPress: () => openTrackContextMenu(context, ref, tracks[i]),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton
// ---------------------------------------------------------------------------

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding:
          const EdgeInsets.only(top: 16, bottom: AppConstants.shellBottomInset),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ShimmerPlaceholder(lines: 2, lineHeight: 22),
        ),
        SizedBox(height: 16),
        ShimmerRow(count: 3),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ShimmerTrackList(count: 4),
        ),
        SizedBox(height: 24),
        ShimmerRow(count: 3),
      ],
    );
  }
}
