// Este test existe para forzar la compilación de TODO el grafo de la app
// (router, pantallas, providers, audio handler, services). `flutter analyze`
// no valida restricciones de compilación de dependencias (por ejemplo una
// librería que extienda una clase `final` de Flutter), y `flutter test`
// compila con el mismo front-end que el build de producción.
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/app.dart';
import 'package:metmusic/features/album/ui/album_detail_screen.dart';
import 'package:metmusic/features/artist/ui/artist_detail_screen.dart';
import 'package:metmusic/features/canvas/ui/canvas_overlay.dart';
import 'package:metmusic/features/home/ui/home_screen.dart';
import 'package:metmusic/features/library/ui/library_screen.dart';
import 'package:metmusic/features/player/audio/metmusic_audio_handler.dart';
import 'package:metmusic/features/player/ui/full_player_screen.dart';
import 'package:metmusic/features/player/ui/mini_player.dart';
import 'package:metmusic/features/player/ui/queue_sheet.dart';
import 'package:metmusic/features/playlist/ui/add_to_playlist_sheet.dart';
import 'package:metmusic/features/playlist/ui/playlist_detail_screen.dart';
import 'package:metmusic/features/search/ui/search_screen.dart';
import 'package:metmusic/features/settings/ui/settings_screen.dart';
import 'package:metmusic/main.dart' as entrypoint;
import 'package:metmusic/navigation/app_router.dart';
import 'package:metmusic/navigation/main_shell.dart';
import 'package:metmusic/navigation/routes.dart';

void main() {
  test('todo el grafo de la app compila', () {
    // Raíz y navegación.
    expect(MetMusicApp, isNotNull);
    expect(routerProvider, isNotNull);
    expect(entrypoint.main, isNotNull);
    expect(MainShell.new, isNotNull);

    // Pantallas del shell.
    expect(HomeScreen.new, isNotNull);
    expect(SearchScreen.new, isNotNull);
    expect(LibraryScreen.new, isNotNull);
    expect(SettingsScreen.new, isNotNull);

    // Pantallas de detalle.
    expect(AlbumDetailScreen.new, isNotNull);
    expect(ArtistDetailScreen.new, isNotNull);
    expect(PlaylistDetailScreen.new, isNotNull);

    // Reproductor.
    expect(FullPlayerScreen.new, isNotNull);
    expect(MiniPlayer.new, isNotNull);
    expect(QueueSheet.new, isNotNull);
    expect(AddToPlaylistSheet.new, isNotNull);
    expect(CanvasOverlay.new, isNotNull);
    expect(MetMusicAudioHandler.new, isNotNull);
  });

  test('las rutas del shell están bien definidas', () {
    expect(Routes.shellPaths.length, 4);
    expect(Routes.indexOf('/home'), 0);
    expect(Routes.indexOf('/search'), 1);
    expect(Routes.indexOf('/library'), 2);
    expect(Routes.indexOf('/settings'), 3);
    expect(Routes.indexOf('/desconocido'), 0);

    expect(Routes.albumPath('42'), '/album/42');
    expect(Routes.artistPath('42'), '/artist/42');
    expect(Routes.playlistPath('uuid'), '/playlist/uuid');
    expect(Routes.userPlaylistPath('p1'), '/user-playlist/p1');
    expect(Routes.album, '/album/:albumId');
  });
}
