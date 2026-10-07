import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/lyrics.dart';
import 'package:metmusic/core/models/search_results.dart';
import 'package:metmusic/core/models/stream_info.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/core/network/api_endpoints.dart';
import 'package:metmusic/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    test('formatea minutos y segundos', () {
      expect(DurationFormatter.format(const Duration(seconds: 5)), '0:05');
      expect(DurationFormatter.format(const Duration(seconds: 320)), '5:20');
    });

    test('usa horas cuando corresponde', () {
      expect(
        DurationFormatter.format(
            const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('formato largo y suma total', () {
      expect(DurationFormatter.long(const Duration(minutes: 3, seconds: 24)),
          '3 min 24 s');
      expect(
        DurationFormatter.total(const [
          Duration(minutes: 1),
          Duration(seconds: 30),
        ]),
        const Duration(seconds: 90),
      );
    });
  });

  group('Track', () {
    test('parsea la respuesta de /api/search', () {
      final track = Track.fromJson(const {
        'track_id': '1550546',
        'title': 'One More Time',
        'artist': 'Daft Punk',
        'artist_id': '123',
        'album': 'Discovery',
        'album_id': '456',
        'duration_seconds': 320,
        'isrc': 'GBDUW0000053',
        'thumbnails': [
          {'url': 'https://img/160.jpg', 'width': 160, 'height': 160},
          {'url': 'https://img/640.jpg', 'width': 640, 'height': 640},
        ],
        'quality': 'HI_RES',
        'explicit': false,
      });

      expect(track.trackId, '1550546');
      expect(track.displayTitle, 'One More Time');
      expect(track.duration, const Duration(seconds: 320));
      expect(track.thumbnailUrl, 'https://img/640.jpg');
      expect(track.listThumbnailUrl, 'https://img/160.jpg');
    });

    test('displayTitle incluye la versión', () {
      final track = Track.fromJson(const {
        'track_id': '1',
        'title': 'Song',
        'version': 'Remix',
      });
      expect(track.displayTitle, 'Song (Remix)');
    });

    test('tolera campos faltantes', () {
      final track = Track.fromJson(const {});
      expect(track.trackId, '');
      expect(track.title, 'Desconocido');
      expect(track.durationSeconds, 0);
      expect(track.thumbnails, isEmpty);
    });
  });

  group('StreamInfo', () {
    test('detecta DASH y arma la etiqueta de calidad', () {
      final info = StreamInfo.fromJson(const {
        'url': 'https://x/manifest.mpd',
        'manifest_type': 'dash',
        'codec': 'flac',
        'bit_depth': 24,
        'sample_rate': 96000,
        'bitrate': 4608,
        'expires_in': 3600,
        'track_id': '1550546',
      });

      expect(info.isDash, isTrue);
      expect(info.isDirect, isFalse);
      expect(info.qualityLabel, 'FLAC 24/96');
      expect(info.isExpired, isFalse);
    });

    test('usa kbps cuando no hay bit depth', () {
      final info = StreamInfo.fromJson(const {
        'url': 'https://x/a.mp4',
        'manifest_type': 'direct',
        'codec': 'mp4',
        'bitrate': 320000,
      });
      expect(info.isDirect, isTrue);
      expect(info.qualityLabel, 'MP4 320 kbps');
    });

    test('marca expiradas las URLs vencidas', () {
      final info = StreamInfo.fromJson(const {
        'url': 'https://x/a',
        'expires_in': -10,
      });
      expect(info.isExpired, isTrue);
    });
  });

  group('Lyrics', () {
    test('parsea synced_lines', () {
      final lyrics = Lyrics.fromJson(const {
        'is_synced': true,
        'synced_lines': [
          {'time_ms': 5000, 'text': 'Segunda'},
          {'time_ms': 1000, 'text': 'Primera'},
        ],
      });

      expect(lyrics.hasSynced, isTrue);
      expect(lyrics.syncedLines.first.text, 'Primera');
      expect(lyrics.syncedLines.first.time, const Duration(seconds: 1));
    });

    test('cae a LRC cuando no hay synced_lines', () {
      final lyrics = Lyrics.fromJson(const {
        'is_synced': true,
        'lrc': '[00:12.50]Hello\n[01:02.00]World',
      });

      expect(lyrics.syncedLines.length, 2);
      expect(lyrics.syncedLines.first.timeMs, 12500);
      expect(lyrics.syncedLines.last.timeMs, 62000);
    });

    test('lee sync_level word con palabras por línea', () {
      final lyrics = Lyrics.fromJson(const {
        'track_id': '1550546',
        'lyrics': 'One more time',
        'provider': 'lyricsplus',
        'source': 'qApple',
        'sync_level': 'word',
        'is_synced': true,
        'synced_lines': [
          {
            'time_ms': 30370,
            'duration_ms': 4130,
            'text': 'One more time',
            'words': [
              {'time_ms': 30370, 'duration_ms': 1500, 'text': 'One more '},
              {'time_ms': 31870, 'duration_ms': 2630, 'text': 'time'},
            ],
          },
          {'time_ms': 40000, 'text': ''},
        ],
      });

      expect(lyrics.level, LyricsSyncLevel.word);
      expect(lyrics.provider, 'lyricsplus');
      expect(lyrics.source, 'qApple');
      // La línea vacía (silencio) se filtra en el parseo.
      expect(lyrics.syncedLines.length, 1);
      final line = lyrics.syncedLines.first;
      expect(line.durationMs, 4130);
      expect(line.words.length, 2);
      expect(line.words.first.durationMs, 1500);
      // duration_ms manda para el fin de la palabra.
      expect(line.wordEndMs(0), 31870);
      expect(line.wordEndMs(1), 34500);
    });

    test('sync_level none no deriva tiempos del LRC', () {
      final lyrics = Lyrics.fromJson(const {
        'lyrics': 'Texto plano',
        'sync_level': 'none',
        'is_synced': false,
        'lrc': '[00:12.50]Hello',
      });

      expect(lyrics.level, LyricsSyncLevel.none);
      expect(lyrics.syncedLines, isEmpty);
      expect(lyrics.hasSynced, isFalse);
      expect(lyrics.hasLyrics, isTrue);
    });

    test('sync_level ausente se infiere de las palabras', () {
      final lyrics = Lyrics.fromJson(const {
        'is_synced': true,
        'synced_lines': [
          {
            'time_ms': 0,
            'text': 'Hola',
            'words': [
              {'time_ms': 0, 'text': 'Hola'},
            ],
          },
        ],
      });

      expect(lyrics.level, LyricsSyncLevel.word);
    });

    test('activeLineIndex sigue la ventana del contrato', () {
      final lyrics = Lyrics.fromJson(const {
        'sync_level': 'line',
        'is_synced': true,
        'synced_lines': [
          {'time_ms': 1000, 'duration_ms': 500, 'text': 'Primera'},
          {'time_ms': 3000, 'text': 'Segunda'},
        ],
      });

      expect(lyrics.activeLineIndex(999), -1); // antes del primer verso
      expect(lyrics.activeLineIndex(1000), 0);
      expect(lyrics.activeLineIndex(1499), 0);
      expect(lyrics.activeLineIndex(1500), -1); // silencio con duration_ms
      expect(lyrics.activeLineIndex(2500), -1);
      expect(lyrics.activeLineIndex(3500), 1); // sin duration → hasta el fin
    });
  });

  group('SearchResults', () {
    test('parsea todas las categorías', () {
      final results = SearchResults.fromJson(const {
        'tracks': [
          <String, dynamic>{'track_id': '1', 'title': 'A'},
        ],
        'albums': [
          <String, dynamic>{'album_id': '2', 'title': 'B'},
        ],
        'artists': [
          <String, dynamic>{'artist_id': '3', 'name': 'C'},
        ],
        'playlists': [
          <String, dynamic>{'playlist_id': '4', 'title': 'D'},
        ],
        'total_results': 297,
      }, query: 'daft');

      expect(results.isEmpty, isFalse);
      expect(results.count, 4);
      expect(results.totalResults, 297);
      expect(results.query, 'daft');
    });
  });

  group('ApiEndpoints', () {
    test('construye rutas tipadas', () {
      expect(ApiEndpoints.health, '/api/health');
      expect(ApiEndpoints.stream('1550546'), '/api/stream/1550546');
      expect(ApiEndpoints.userPlaylistTrack('p1', 't9'),
          '/api/user/playlists/p1/tracks/t9');
      expect(ApiEndpoints.userFavoritesCheck, '/api/user/favorites/check');
    });
  });
}
