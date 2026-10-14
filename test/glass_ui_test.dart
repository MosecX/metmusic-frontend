import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/core/models/album.dart';
import 'package:metmusic/core/models/track.dart';
import 'package:metmusic/core/network/api_exception.dart';
import 'package:metmusic/core/theme/app_colors.dart';
import 'package:metmusic/core/widgets/album_card.dart';
import 'package:metmusic/core/widgets/empty_state.dart';
import 'package:metmusic/core/widgets/glass_card.dart';
import 'package:metmusic/core/widgets/glass_player_card.dart';
import 'package:metmusic/core/widgets/section_header.dart';
import 'package:metmusic/core/widgets/track_row.dart';

BoxDecoration _decorationOf(WidgetTester tester, Type widgetType) {
  final container = tester.widget<Container>(
    find
        .descendant(
            of: find.byType(widgetType), matching: find.byType(Container))
        .first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  group('Glass 2 — GlassCard', () {
    testWidgets('usa relleno blanco 10%, borde 14% y radio 20', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassCard(child: Text('contenido'))),
        ),
      );

      final decoration = _decorationOf(tester, GlassCard);
      // Relleno blanco al 10%.
      expect(decoration.color, AppColors.glassFill);
      expect(decoration.color!.a, closeTo(0.10, 0.01));
      // Borde blanco al 14%.
      final border = decoration.border! as Border;
      expect(border.top.color.a, closeTo(0.14, 0.01));
      // Radio 20.
      expect(
        (decoration.borderRadius as BorderRadius).topLeft.x,
        20,
      );
    });
  });

  group('Glass 1 — GlassPlayerCard', () {
    testWidgets('usa relleno blanco 10%, borde 14% y radio 20', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GlassPlayerCard(child: Text('player'))),
        ),
      );

      final decoration = _decorationOf(tester, GlassPlayerCard);
      expect(decoration.color!.a, closeTo(0.10, 0.01));
      expect(decoration.color!.r, 1.0);
      final border = decoration.border! as Border;
      expect(border.top.color.a, closeTo(0.14, 0.01));
      expect((decoration.borderRadius as BorderRadius).topLeft.x, 20);
    });
  });

  group('TrackRow', () {
    testWidgets('muestra título, artista y duración', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackRow(
              track: Track(
                trackId: '1',
                title: 'One More Time',
                artist: 'Daft Punk',
                durationSeconds: 320,
              ),
            ),
          ),
        ),
      );

      expect(find.text('One More Time'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('5:20'), findsOneWidget);
    });

    testWidgets('incluye el sufijo de versión y el badge explicit',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackRow(
              track: Track(
                trackId: '1',
                title: 'Song',
                version: 'Remix',
                explicit: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Song (Remix)'), findsOneWidget);
      expect(find.text('E'), findsOneWidget);
    });
  });

  group('AlbumCard y SectionHeader', () {
    testWidgets('renderizan metadatos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Novedades',
                  actionLabel: 'Ver todo',
                  onActionTap: () {},
                ),
                const AlbumCard(
                  album: Album(
                    albumId: 'a1',
                    title: 'Discovery',
                    artist: 'Daft Punk',
                    releaseDate: '2001-03-07',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Novedades'), findsOneWidget);
      expect(find.text('Ver todo'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Daft Punk • 2001'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('muestra título y subtítulo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.music_note,
              title: 'Buscá algo para empezar',
              subtitle: 'Encontrá música',
            ),
          ),
        ),
      );

      // EmptyState usa flutter_animate: hay que dejar que la animación termine
      // antes de que el test cierre (si no, quedan timers pendientes).
      await tester.pumpAndSettle();

      expect(find.text('Buscá algo para empezar'), findsOneWidget);
      expect(find.text('Encontrá música'), findsOneWidget);
    });
  });

  group('ApiException', () {
    DioException dioError(int status) => DioException(
          requestOptions: RequestOptions(path: '/api/x'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/x'),
            statusCode: status,
          ),
        );

    test('401 se traduce a token inválido sin reintento', () {
      final error = ApiException.fromDio(dioError(401));
      expect(error, isA<UnauthorizedApiException>());
      expect(error.userMessage, contains('Token inválido'));
      expect(error.isRetryable, isFalse);
    });

    test('404 se traduce a "Track no disponible"', () {
      final error = ApiException.fromDio(dioError(404));
      expect(error, isA<NotFoundApiException>());
      expect(error.userMessage, 'Track no disponible');
    });

    test('502 se traduce a error del servidor de música', () {
      final error = ApiException.fromDio(dioError(502));
      expect(error, isA<ServerApiException>());
      expect(error.userMessage, 'Error del servidor de música');
      expect(error.isRetryable, isTrue);
    });

    test('timeout y fallo de conexión son distinguibles', () {
      final timeout = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/api/x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(timeout, isA<TimeoutApiException>());

      final offline = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/api/x'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(offline, isA<NetworkApiException>());
      expect(offline.userMessage, 'Sin conexión al servidor');
    });
  });
}
