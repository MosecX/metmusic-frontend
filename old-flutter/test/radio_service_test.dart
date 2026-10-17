import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/radio_mix.dart';
import 'package:metmusic/core/network/api_client.dart';
import 'package:metmusic/core/network/api_exception.dart';
import 'package:metmusic/core/network/auth_interceptor.dart';
import 'package:metmusic/services/api/radio_service.dart';

/// Contrato de `GET /api/tracks/{trackId}/radio` verificado contra un
/// servidor HTTP real: 200 se parsea (semilla primero, mix con nulos
/// soportados), 404 devuelve `null` sin reintentos en bucle, 401/5xx se
/// propagan (el 5xx con el único reintento de `ApiClient`).
typedef Step = ({int status, Object? body});

void main() {
  late HttpServer server;
  late ApiClient client;
  late RadioService service;

  /// Secuencia de respuestas; al agotarse responde 200 con `{}`.
  final script = <Step>[];
  var hits = 0;
  String? lastAuthHeader;
  String? lastPath;

  const track = <String, dynamic>{
    'track_id': '424096050',
    'title': 'One More Time',
    'artist': 'Daft Punk',
    'artist_id': '14885395',
    'album': 'Discovery',
    'album_id': '302127',
    'duration_seconds': 320,
    'thumbnails': [
      <String, dynamic>{
        'url': 'https://img/320x320.jpg',
        'width': 320,
        'height': 320,
        'size': '320x320',
      },
    ],
    'popularity': 65.2,
    'quality': 'LOSSLESS',
    'explicit': false,
    'version': 'Album version',
    'stream_ready': true,
    'isrc': null,
    'bpm': null,
    'peak': null,
    'copyright': null,
  };

  const radioPayload = <String, dynamic>{
    'track_id': '424096050',
    'mix': <String, dynamic>{
      'id': 'mix-1',
      'title': 'Estación de Daft Punk',
      'sub_title': 'Daft Punk',
      'description': 'Mezcla a partir de la pista semilla',
      'image_url': 'https://images/signed-mix.jpg',
    },
    'items': [
      track,
      <String, dynamic>{'track_id': '90210', 'title': 'Digital Love'}
    ],
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
    service = RadioService(client);
  });

  tearDown(() async {
    client.dispose();
    await server.close(force: true);
  });

  test('200 → parsea estación, mix e items con Bearer', () async {
    script.add((status: 200, body: radioPayload));

    final station = await service.getRadio('424096050');

    expect(station, isA<RadioStation>());
    expect(station, isNotNull);
    expect(station!.trackId, '424096050');
    expect(station.mix.id, 'mix-1');
    expect(station.mix.title, 'Estación de Daft Punk');
    expect(station.mix.subTitle, 'Daft Punk');
    expect(station.mix.description, 'Mezcla a partir de la pista semilla');
    expect(station.mix.imageUrl, 'https://images/signed-mix.jpg');

    expect(station.items, hasLength(2));
    // El primer item es la pista semilla.
    expect(station.items.first.trackId, '424096050');
    expect(station.items.first.title, 'One More Time');
    expect(station.items.first.artist, 'Daft Punk');
    expect(station.items.first.durationSeconds, 320);
    expect(station.items.first.thumbnails, hasLength(1));
    expect(station.items.first.thumbnails.first.width, 320);
    expect(station.items[1].trackId, '90210');
    // Opcionales nulos del v1 tolerados.
    expect(station.items.first.isrc, isNull);

    expect(lastPath, '/api/tracks/424096050/radio');
    expect(lastAuthHeader, 'Bearer test-token');
    expect(hits, 1);
  });

  test('404 → null sin reintentos (la pista no tiene radio)', () async {
    script.add((
      status: 404,
      body: const {
        'status_code': 404,
        'error': 'not_found',
        'detail': 'la pista no tiene radio',
      },
    ));

    expect(await service.getRadio('999'), isNull);
    expect(hits, 1);
  });

  test('401 → propaga UnauthorizedApiException', () async {
    script.add((
      status: 401,
      body: const {'error': 'unauthorized'},
    ));

    await expectLater(
      service.getRadio('424096050'),
      throwsA(isA<UnauthorizedApiException>()),
    );
    expect(hits, 1);
  });

  test('5xx → reintenta una vez (ApiClient) y propaga ServerApiException',
      () async {
    script.add((
      status: 503,
      body: const {'error': 'http_5xx'},
    ));
    script.add((
      status: 503,
      body: const {'error': 'http_5xx'},
    ));

    await expectLater(
      service.getRadio('424096050'),
      throwsA(isA<ServerApiException>()),
    );
    expect(hits, 2);
  });

  test('items vacíos → null (no arma cola inútil)', () async {
    script.add((
      status: 200,
      body: const {
        'track_id': '424096050',
        'mix': <String, dynamic>{'id': 'mix-1', 'title': 'Estación'},
        'items': <dynamic>[],
      },
    ));

    expect(await service.getRadio('424096050'), isNull);
    expect(hits, 1);
  });
}
