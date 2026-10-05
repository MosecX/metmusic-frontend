import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/album.dart';
import '../../../core/models/artist.dart';
import '../../../core/models/playlist.dart';
import '../../../core/models/search_results.dart';
import '../../../core/models/track.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/album_card.dart';
import '../../../core/widgets/artist_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/playlist_card.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/routes.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../models/search_models.dart';
import '../providers/search_provider.dart';

/// Pantalla de búsqueda con tabs por tipo de contenido.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: SearchType.values.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(searchProvider.notifier).setType(SearchType.values[_tabs.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: _SearchField(
            controller: _input,
            onChanged: (value) =>
                ref.read(searchProvider.notifier).updateQuery(value),
            onSubmitted: (_) => ref.read(searchProvider.notifier).submit(),
            onClear: () {
              _input.clear();
              ref.read(searchProvider.notifier).clear();
            },
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: [
            for (final type in SearchType.values) Tab(text: type.label),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: _Results(state: state)),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Canciones, álbumes, artistas…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(LucideIcons.x,
                        size: 16, color: AppColors.textTertiary),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerTrackList(count: 7),
      );
    }

    if (state.error != null) {
      return ErrorState(
        error: state.error!,
        onRetry: () => ref.read(searchProvider.notifier).submit(),
      );
    }

    if (state.showEmptyPrompt) {
      return const EmptyState(
        icon: LucideIcons.search,
        title: 'Buscá algo para empezar',
        subtitle: 'Encontrá canciones, álbumes, artistas y playlists.',
      );
    }

    if (state.showNoResults) {
      return EmptyState(
        icon: LucideIcons.music,
        title: 'Sin resultados',
        subtitle: 'No encontramos nada para "${state.query}".',
      );
    }

    final results = state.results;
    return switch (state.type) {
      SearchType.all => _AllResults(results: results),
      SearchType.tracks => _TrackResults(
          tracks: results.tracks,
          title: 'Canciones',
        ),
      SearchType.albums => _AlbumResults(albums: results.albums),
      SearchType.artists => _ArtistResults(artists: results.artists),
      SearchType.playlists => _PlaylistResults(playlists: results.playlists),
    };
  }
}

// ---------------------------------------------------------------------------
// Listas de resultados
// ---------------------------------------------------------------------------

class _AllResults extends ConsumerWidget {
  const _AllResults({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      children: [
        if (results.tracks.isNotEmpty) ...[
          const _GroupTitle('Canciones', onMore: null),
          _TrackList(results.tracks),
        ],
        if (results.albums.isNotEmpty) ...[
          const _GroupTitle('Álbumes'),
          _AlbumList(results.albums),
        ],
        if (results.artists.isNotEmpty) ...[
          const _GroupTitle('Artistas'),
          _ArtistList(results.artists),
        ],
        if (results.playlists.isNotEmpty) ...[
          const _GroupTitle('Playlists'),
          _PlaylistList(results.playlists),
        ],
      ],
    );
  }
}

class _TrackResults extends ConsumerWidget {
  const _TrackResults({required this.tracks, required this.title});

  final List<Track> tracks;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tracks.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.music,
        title: 'Sin canciones',
        subtitle: 'Probá con otra búsqueda.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      children: [_TrackList(tracks)],
    );
  }
}

class _AlbumResults extends StatelessWidget {
  const _AlbumResults({required this.albums});

  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.disc3,
        title: 'Sin álbumes',
        subtitle: 'Probá con otra búsqueda.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      children: [_AlbumList(albums)],
    );
  }
}

class _ArtistResults extends StatelessWidget {
  const _ArtistResults({required this.artists});

  final List<Artist> artists;

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.user,
        title: 'Sin artistas',
        subtitle: 'Probá con otra búsqueda.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      children: [_ArtistList(artists)],
    );
  }
}

class _PlaylistResults extends StatelessWidget {
  const _PlaylistResults({required this.playlists});

  final List<Playlist> playlists;

  @override
  Widget build(BuildContext context) {
    if (playlists.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.listMusic,
        title: 'Sin playlists',
        subtitle: 'Probá con otra búsqueda.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 160),
      children: [_PlaylistList(playlists)],
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList(this.tracks);

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
                showAlbum: true,
                onTap: () =>
                    ref.playTrack(tracks[i], context: tracks, index: i),
                onPlayTap: () =>
                    ref.playTrack(tracks[i], context: tracks, index: i),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumList extends StatelessWidget {
  const _AlbumList(this.albums);

  final List<Album> albums;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => AlbumCard(
          album: albums[index],
          onTap: () => context.push(Routes.albumPath(albums[index].albumId)),
        ),
      ),
    );
  }
}

class _ArtistList extends StatelessWidget {
  const _ArtistList(this.artists);

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
        itemBuilder: (context, index) => ArtistCard(
          artist: artists[index],
          size: 110,
          onTap: () => context.push(Routes.artistPath(artists[index].artistId)),
        ),
      ),
    );
  }
}

class _PlaylistList extends StatelessWidget {
  const _PlaylistList(this.playlists);

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
        itemBuilder: (context, index) => PlaylistCard(
          playlist: playlists[index],
          onTap: () =>
              context.push(Routes.playlistPath(playlists[index].playlistId)),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.title, {this.onMore});

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.title),
          const Spacer(),
          if (onMore != null)
            TextButton(onPressed: onMore, child: const Text('Ver todo')),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
