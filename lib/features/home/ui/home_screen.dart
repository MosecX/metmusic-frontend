import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      padding: const EdgeInsets.only(top: 12, bottom: 160),
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
          const SizedBox(height: 24),
        ],
        if (data.newReleases.isNotEmpty) ...[
          const SectionHeader(
            title: 'Novedades',
            icon: LucideIcons.disc3,
          ),
          _AlbumCarousel(albums: data.newReleases),
          const SizedBox(height: 24),
        ],
        if (data.charts.isNotEmpty) ...[
          const SectionHeader(
            title: 'Top canciones',
            icon: LucideIcons.zap,
          ),
          _TrackListCard(tracks: data.charts),
          const SizedBox(height: 24),
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
      widgets.add(const SizedBox(height: 24));
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
    final (text, emoji) = switch (hour) {
      >= 6 && < 12 => ('Buenos días', '☀️'),
      >= 12 && < 20 => ('Buenas tardes', '🌤'),
      _ => ('Buenas noches', '🌙'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$text $emoji', style: AppTextStyles.headline),
          const SizedBox(height: 4),
          const Text('¿Qué querés escuchar hoy?', style: AppTextStyles.subtitle),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        fill: active ? AppColors.accent.withValues(alpha: 0.18) : null,
        onTap: onTap,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: active ? AppColors.accent : AppColors.textSecondary,
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
        const SectionHeader(
          title: 'Escuchado recientemente',
          icon: LucideIcons.history,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < tracks.length; i++)
                  TrackRow(
                    track: tracks[i],
                    onTap: () =>
                        ref.playTrack(tracks[i], context: tracks, index: i),
                    onPlayTap: () =>
                        ref.playTrack(tracks[i], context: tracks, index: i),
                    onLongPress: () =>
                        openTrackContextMenu(context, ref, tracks[i]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlbumCarousel extends ConsumerWidget {
  const _AlbumCarousel({required this.albums});

  final List<Album> albums;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
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
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ArtistCard(
            artist: artist,
            size: 110,
            onTap: () => context.push(Routes.artistPath(artist.artistId)),
          );
        },
      ),
    );
  }
}

class _TrackListCard extends ConsumerWidget {
  const _TrackListCard({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(playerProvider).track?.trackId;
    final playing = ref.watch(playerProvider.select((s) => s.playing));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < tracks.length; i++)
              TrackRow(
                track: tracks[i],
                isActive: tracks[i].trackId == currentId,
                isPlaying: playing,
                onTap: () => ref.playTrack(tracks[i], context: tracks, index: i),
                onPlayTap: () =>
                    ref.playTrack(tracks[i], context: tracks, index: i),
                onLongPress: () =>
                    openTrackContextMenu(context, ref, tracks[i]),
              ),
          ],
        ),
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
      padding: const EdgeInsets.only(top: 16, bottom: 160),
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
