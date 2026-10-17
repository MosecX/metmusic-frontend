import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/network/api_client.dart';
import 'package:metmusic/core/network/api_exception.dart';
import 'package:metmusic/core/network/auth_interceptor.dart';
import 'package:metmusic/services/api/track_service.dart';

/// Contrato de `GET /api/tracks/{trackId}` para el modal de metadatos:
/// TrackSchema completo (nulos y numéricos tolerantes), el envoltorio
/// `{track: {...}}` del backend y los errores propagados a la UI.
typedef Step = ({int status, Object? body});

void main() {
  late HttpServer server;
  late ApiClient client;
  late TrackService service;

  /// Secuencia de respuestas; al agotarse responde 200 con `{}`.
  final script = <Step>[];
  var hits = 0;
  String? lastAuthHeader;
  String? lastPath;

  const payload = <String, dynamic>{
    'track_id': '424096050',
    'title': 'One More Time',
    'artist': 'Daft Punk',
    'artist_id': '14885395',
    'album': 'Discovery',
    'album_id': '302127',
    'duration_seconds': 320,
    'isrc': 'GBDUW0000059',
    'quality': 'LOSSLESS',
    'version': 'Album version',
    'copyright': '(P) 2001 Daft Life Ltd.',
    'popularity': 65.2,
    'bpm': '123',
    'peak': -1.2,
    'explicit': false,
    'stream_ready': true,
  };

  setUp(() async {
    hits = 0;
    lastAuthHeader = null;
    lastPath = null;
    script.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      hits++;
      lastAuthHeader = request.headers.value(HttpHeaders.authorizationHeader);
      lastPath = request.uri.path;
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
    service = TrackService(client);
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  test('200 → parsea el TrackSchema completo con Bearer', () async {
    script.add((status: 200, body: payload));

    final details = await service.getTrackDetails('424096050');

    expect(details.trackId, '424096050');
    expect(details.title, 'One More Time');
    expect(details.artist, 'Daft Punk');
    expect(details.artistId, '14885395');
    expect(details.album, 'Discovery');
    expect(details.albumId, '302127');
    expect(details.durationSeconds, 320);
    expect(details.isrc, 'GBDUW0000059');
    expect(details.quality, 'LOSSLESS');
    expect(details.version, 'Album version');
    expect(details.copyright, '(P) 2001 Daft Life Ltd.');
    expect(details.popularity, closeTo(65.2, 0.001));
    expect(details.bpm, 123.0); // viene como string
    expect(details.peak, closeTo(-1.2, 0.001));
    expect(details.explicit, isFalse);
    expect(details.streamReady, isTrue);

    expect(lastPath, '/api/tracks/424096050');
    expect(lastAuthHeader, 'Bearer test-token');
    expect(hits, 1);
  });

  test('200 envuelto en {track: {...}} → lo desenvuelve', () async {
    script.add((
      status: 200,
      body: <String, dynamic>{'track': payload},
    ));

    final details = await service.getTrackDetails('424096050');
    expect(details.title, 'One More Time');

    // getTrack comparte el mismo unwrap.
    script.add((
      status: 200,
      body: <String, dynamic>{'track': payload},
    ));
    final track = await service.getTrack('424096050');
    expect(track.trackId, '424096050');
    expect(track.isrc, 'GBDUW0000059');
    expect(hits, 2);
  });

  test('404 → propaga NotFoundApiException (el modal muestra el error)',
      () async {
    script.add((
      status: 404,
      body: const {'error': 'not_found', 'detail': 'track inexistente'},
    ));

    await expectLater(
      service.getTrackDetails('999'),
      throwsA(isA<NotFoundApiException>()),
    );
    expect(hits, 1);
  });
}
