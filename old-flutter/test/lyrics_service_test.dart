import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/lyrics.dart';
import 'package:metmusic/core/network/api_client.dart';
import 'package:metmusic/core/network/auth_interceptor.dart';
import 'package:metmusic/services/api/lyrics_service.dart';

/// Contrato de `GET /api/lyrics/{trackId}` verificado contra un servidor
/// HTTP real: 200 se parsea, 404/401 no reintenta en bucle, 429 hace un
/// reintento con backoff y degrada a null, 5xx reintenta una vez (por el
/// interceptor de ApiClient) y degrada a null.
typedef Step = ({int status, Object? body});

void main() {
  late HttpServer server;
  late ApiClient client;
  late LyricsService service;

  /// Secuencia de respuestas; al agotarse responde 200 con `{}`.
  final script = <Step>[];
  var hits = 0;
  String? lastAuthHeader;

  const wordPayload = <String, dynamic>{
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
    ],
    'lrc': '[00:30.37]One more time',
  };

  setUp(() async {
    hits = 0;
    lastAuthHeader = null;
    script.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      hits++;
      lastAuthHeader = request.headers.value(HttpHeaders.authorizationHeader);
      final step = script.isNotEmpty
          ? script.removeAt(0)
          : (status: 200, body: <String, dynamic>{});
      request.response.statusCode = step.status;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(step.body));
      await request.response.close();
    });
    client = ApiClient(
      baseUrl: BaseUrlHolder('http://127.0.0.1:${server.port}'),
      token: ApiTokenHolder('test-token'),
    );
    service = LyricsService(client);
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  test('200 → parsea el contrato word con Bearer', () async {
    script.add((status: 200, body: wordPayload));

    final lyrics = await service.getLyrics('1550546');

    expect(lyrics, isNotNull);
    expect(lyrics!.trackId, '1550546');
    expect(lyrics.level, LyricsSyncLevel.word);
    expect(lyrics.provider, 'lyricsplus');
    expect(lyrics.syncedLines, hasLength(1));
    expect(lyrics.syncedLines.first.words, hasLength(2));
    expect(lyrics.activeLineIndex(31000), 0);
    expect(hits, 1);
    expect(lastAuthHeader, 'Bearer test-token');
  });

  test('404 → null sin reintentos (usa fuente local)', () async {
    script.add((
      status: 404,
      body: const {
        'error': 'not_found',
        'detail': 'lyricsplus no tiene letras',
      },
    ));

    expect(await service.getLyrics('999'), isNull);
    expect(hits, 1);
  });

  test('401 → null sin reintentos', () async {
    script.add((
      status: 401,
      body: const {'error': 'unauthorized'},
    ));

    expect(await service.getLyrics('1550546'), isNull);
    expect(hits, 1);
  });

  test('429 → un reintento con backoff y después el 200 se parsea', () async {
    script.add((
      status: 429,
      body: const {'error': 'rate_limited'},
    ));
    script.add((status: 200, body: wordPayload));

    final lyrics = await service.getLyrics('1550546');

    expect(lyrics, isNotNull);
    expect(lyrics!.level, LyricsSyncLevel.word);
    expect(hits, 2);
  });

  test('429 persistente → degrada a null tras el reintento', () async {
    script.add((
      status: 429,
      body: const {'error': 'rate_limited'},
    ));
    script.add((
      status: 429,
      body: const {'error': 'rate_limited'},
    ));

    expect(await service.getLyrics('1550546'), isNull);
    expect(hits, 2);
  });

  test('5xx → reintenta una vez (ApiClient) y degrada a null', () async {
    script.add((
      status: 503,
      body: const {'error': 'http_5xx'},
    ));
    script.add((
      status: 503,
      body: const {'error': 'http_5xx'},
    ));

    expect(await service.getLyrics('1550546'), isNull);
    expect(hits, 2);
  });
}
