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
import '../features/playlist/ui/playlist_detail_screen.dart';
import '../features/search/ui/search_screen.dart';
import '../features/settings/ui/settings_screen.dart';
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
        builder: (_, state) =>
            AlbumDetailScreen(albumId: state.pathParameters['albumId'] ?? ''),
      ),
      GoRoute(
        path: Routes.artist,
        name: Routes.artistName,
        builder: (_, state) =>
            ArtistDetailScreen(artistId: state.pathParameters['artistId'] ?? ''),
      ),
      GoRoute(
        path: Routes.playlist,
        name: Routes.playlistName,
        builder: (_, state) => PlaylistDetailScreen(
          playlistId: state.pathParameters['playlistId'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.userPlaylist,
        name: Routes.userPlaylistName,
        builder: (_, state) => PlaylistDetailScreen(
          playlistId: state.pathParameters['playlistId'] ?? '',
          isUserPlaylist: true,
        ),
      ),
      GoRoute(
        path: Routes.player,
        name: Routes.playerName,
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 320),
          child: const FullPlayerScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
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
