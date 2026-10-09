import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
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
import '../../../core/widgets/playlist_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/routes.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../../player/ui/track_context_menu.dart';
import '../models/search_models.dart';
import '../providers/search_provider.dart';

/// Pantalla de búsqueda: título grande, campo iOS, filtro segmentado y
/// resultados (o grid "Explorar" cuando no hay query).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// Rellena el campo con un género del grid "Explorar" y busca.
  void _browsePick(String label) {
    _input.text = label;
    final notifier = ref.read(searchProvider.notifier);
    notifier.updateQuery(label);
    notifier.submit();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('Buscar', style: AppTextStyles.largeTitle),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedControl(
            labels: [for (final type in SearchType.values) type.label],
            selectedIndex: SearchType.values.indexOf(state.type),
            fontSize: 12,
            onChanged: (index) =>
                ref.read(searchProvider.notifier).setType(SearchType.values[index]),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _Results(state: state, onBrowsePick: _browsePick),
        ),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.controlFill,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.only(left: 13, right: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.search,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(fontSize: 17, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Artistas, canciones, álbumes…',
                hintStyle: TextStyle(
                  fontSize: 17,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
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
  const _Results({required this.state, required this.onBrowsePick});

  final SearchState state;
  final ValueChanged<String> onBrowsePick;

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
      return _Browse(onPick: onBrowsePick);
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
      SearchType.tracks => _TrackResults(results.tracks),
      SearchType.albums => _AlbumResults(albums: results.albums),
      SearchType.artists => _ArtistResults(artists: results.artists),
      SearchType.playlists => _PlaylistResults(playlists: results.playlists),
    };
  }
}

// ---------------------------------------------------------------------------
// Explorar (estado vacío)
// ---------------------------------------------------------------------------

/// Grid de géneros estilo boceto: tiles con degradado y disco decorativo.
class _Browse extends StatelessWidget {
  const _Browse({required this.onPick});

  final ValueChanged<String> onPick;

  static const List<(String, Color, Color)> _tiles = [
    ('Éxitos latinos', Color(0xFFFC466B), Color(0xFF3F5EFB)),
    ('Pop', Color(0xFF8E2DE2), Color(0xFF4A00E0)),
    ('Rock', Color(0xFFF7971E), Color(0xFFFFD200)),
    ('Chill', Color(0xFF2B6CB0), Color(0xFF63B3ED)),
    ('Hip-Hop', Color(0xFF0F2027), Color(0xFF2C5364)),
    ('Baladas', Color(0xFFFF758C), Color(0xFFFF7EB3)),
    ('Corridos', Color(0xFF11998E), Color(0xFF38EF7D)),
    ('Indie', Color(0xFF355C7D), Color(0xFFC06C84)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
      children: [
        const SectionHeader(title: 'Explorar'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 96,
              crossAxisSpacing: 13,
              mainAxisSpacing: 13,
            ),
            itemCount: _tiles.length,
            itemBuilder: (context, index) {
              final (label, from, to) = _tiles[index];
              return _BrowseTile(
                label: label,
                from: from,
                to: to,
                onTap: () => onPick(label),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.label,
    required this.from,
    required this.to,
    required this.onTap,
  });

  final String label;
  final Color from;
  final Color to;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 96,
          child: Stack(
            children: [
              // Degradado 135°.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [from, to],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              // Disco decorativo.
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Velo inferior para legibilidad.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 1],
                    colors: [Colors.transparent, Color(0x59000000)],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0x59000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
      children: [
        if (results.tracks.isNotEmpty) ...[
          const SectionHeader(title: 'Canciones'),
          _TrackList(results.tracks),
        ],
        if (results.albums.isNotEmpty) ...[
          const SectionHeader(title: 'Álbumes'),
          _AlbumList(results.albums),
        ],
        if (results.artists.isNotEmpty) ...[
          const SectionHeader(title: 'Artistas'),
          _ArtistList(results.artists),
        ],
        if (results.playlists.isNotEmpty) ...[
          const SectionHeader(title: 'Playlists'),
          _PlaylistList(results.playlists),
        ],
      ],
    );
  }
}

class _TrackResults extends ConsumerWidget {
  const _TrackResults(this.tracks);

  final List<Track> tracks;

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
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
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
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
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
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
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
      padding: const EdgeInsets.only(bottom: AppConstants.shellBottomInset),
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
              onLongPress: () =>
                  openTrackContextMenu(context, ref, tracks[i]),
            ),
        ],
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
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
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
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => ArtistCard(
          artist: artists[index],
          size: 108,
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
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => PlaylistCard(
          playlist: playlists[index],
          onTap: () =>
              context.push(Routes.playlistPath(playlists[index].playlistId)),
        ),
      ),
    );
  }
}
