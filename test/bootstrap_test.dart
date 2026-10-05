import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/bootstrap/app_bootstrap.dart';

void main() {
  group('AppDiagnostics', () {
    test('guarda los errores para poder mostrarlos sin logcat', () {
      AppDiagnostics.record('test', 'mensaje de prueba');
      expect(AppDiagnostics.entries.any((e) => e.contains('mensaje de prueba')),
          isTrue);
      expect(AppDiagnostics.summary, contains('mensaje de prueba'));
    });

    test('anota el modo degradado del audio', () {
      AppDiagnostics.note('init', 'Audio sin MediaSession');
      expect(AppDiagnostics.runtime['init'], 'Audio sin MediaSession');
    });

    test('el buffer no crece sin límite', () {
      for (var i = 0; i < 40; i++) {
        AppDiagnostics.record('test', 'error $i');
      }
      expect(AppDiagnostics.entries.length, lessThanOrEqualTo(20));
    });
  });

  group('BootFailure', () {
    test('incluye el paso que falló', () {
      final failure = BootFailure(
        'Almacenamiento local (Hive)',
        Exception('boom'),
        StackTrace.current,
      );
      expect(failure.toString(), contains('Almacenamiento local (Hive)'));
      expect(failure.toString(), contains('boom'));
    });
  });

  group('Arranque sin plugins (como en un fallo real de init)', () {
    testWidgets('monta la UI de inmediato: nunca queda sólo el fondo',
        (tester) async {
      // Sin mocks de plataforma, Hive y SharedPreferences fallan: es
      // exactamente el escenario del arranque roto en el dispositivo.
      await tester.pumpWidget(const AppBootstrap());
      await tester.pump();

      // El spinner gira para siempre, así que no se puede usar pumpAndSettle.
      expect(find.byType(AppBootstrap), findsOneWidget);
      expect(find.text('Iniciando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('el error de arranque se muestra con el paso y botón de reintento',
        (tester) async {
      await tester.pumpWidget(const AppBootstrap());
      await tester.pump();

      // Deja que las promesas reales de init se resuelvan (o fallen).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pump();

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');

      expect(texts, contains('No se pudo iniciar MetMusic'));
      expect(texts, contains('Paso:'));
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('AppErrorSurface', () {
    testWidgets('muestra el mensaje del error en vez de un cuadro vacío',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: AppErrorSurface(message: 'Null check operator used on a null value'),
        ),
      );

      expect(find.text('MetMusic encontró un error'), findsOneWidget);
      expect(
        find.text('Null check operator used on a null value'),
        findsOneWidget,
      );
    });
  });
}