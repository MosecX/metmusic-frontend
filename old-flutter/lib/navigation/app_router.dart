import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/empty_state.dart';
import '../features/album/ui/album_detail_screen.dart';
import '../features/artist/ui/artist_detail_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/library/ui/library_screen.dart';
import '../features/player/ui/full_player_screen.dart';
import '../features/player/ui/mix_screen.dart';
import '../features/playlist/ui/playlist_detail_screen.dart';
import '../features/search/ui/search_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import 'app_page_transitions.dart';
import 'main_shell.dart';
import 'routes.dart';

/// Router global de la aplicación.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: kDebugMode,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            name: Routes.homeName,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.search,
            name: Routes.searchName,
            builder: (_, __) => const SearchScreen(),
          ),
          GoRoute(
            path: Routes.library,
            name: Routes.libraryName,
            builder: (_, __) => const LibraryScreen(),
          ),
          GoRoute(
            path: Routes.settings,
            name: Routes.settingsName,
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.album,
        name: Routes.albumName,
        pageBuilder: (_, state) => AppPageTransitions.push<void>(
          key: state.pageKey,
          child: AlbumDetailScreen(
            albumId: state.pathParameters['albumId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: Routes.artist,
        name: Routes.artistName,
        pageBuilder: (_, state) => AppPageTransitions.push<void>(
          key: state.pageKey,
          child: ArtistDetailScreen(
            artistId: state.pathParameters['artistId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: Routes.playlist,
        name: Routes.playlistName,
        pageBuilder: (_, state) => AppPageTransitions.push<void>(
          key: state.pageKey,
          child: PlaylistDetailScreen(
            playlistId: state.pathParameters['playlistId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: Routes.mix,
        name: Routes.mixName,
        pageBuilder: (_, state) => AppPageTransitions.push<void>(
          key: state.pageKey,
          child: MixScreen(
            trackId: state.pathParameters['trackId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: Routes.userPlaylist,
        name: Routes.userPlaylistName,
        pageBuilder: (_, state) => AppPageTransitions.push<void>(
          key: state.pageKey,
          child: PlaylistDetailScreen(
            playlistId: state.pathParameters['playlistId'] ?? '',
            isUserPlaylist: true,
          ),
        ),
      ),
      GoRoute(
        path: Routes.player,
        name: Routes.playerName,
        pageBuilder: (_, state) => AppPageTransitions.modalUp<void>(
          key: state.pageKey,
          child: const FullPlayerScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.black,
      body: EmptyState(
        icon: Icons.error_outline,
        title: 'Ruta no encontrada',
        subtitle: state.uri.toString(),
        action: FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Volver al inicio'),
        ),
      ),
    ),
  );
});
