import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metmusic/bootstrap/app_bootstrap.dart';

/// Réplica exacta del patrón de `PlayerController`: un provider que dentro de
/// su constructor lee otro provider que *solo* existe por override.
///
/// Si el contenedor de providers no es el que lleva los overrides, la lectura
/// tira `UnimplementedError` y el fallo queda a la vista en vez de ser un
/// `ProviderNotFoundException` silencioso.
class _FakeHandler {
  _FakeHandler(this.id);

  final String id;
}

final _handlerProvider = Provider<_FakeHandler>(
  (ref) => throw UnimplementedError('debe sobrescribirse'),
);

class _Controller extends StateNotifier<int> {
  _Controller(this._ref) : super(0) {
    // Lectura indirecta dentro del constructor, igual que `PlayerController`
    // con `audioHandlerProvider`: es el caso que se rompe si el contenedor
    // raíz no lleva los overrides.
    state = _ref.read(_handlerProvider).id.length;
  }

  final Ref _ref;
}

final _indirectProvider =
    StateNotifierProvider<_Controller, int>(_Controller.new);

/// Lee el `DefaultTextStyle` efectivo en el punto donde se inserta.
class _StyleProbe extends StatelessWidget {
  const _StyleProbe({required this.onStyle});

  final ValueChanged<TextStyle> onStyle;

  @override
  Widget build(BuildContext context) {
    onStyle(DefaultTextStyle.of(context).style);
    return const SizedBox.shrink();
  }
}

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

    testWidgets(
        'el error de arranque se muestra con el paso y botón de reintento',
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
          child: AppErrorSurface(
              message: 'Null check operator used on a null value'),
        ),
      );

      expect(find.text('MetMusic encontró un error'), findsOneWidget);
      expect(
        find.text('Null check operator used on a null value'),
        findsOneWidget,
      );
    });

    testWidgets('sin Scaffold ni Material encima, NO subraya en amarillo',
        (tester) async {
      // Éste era el segundo bug: el widget se dibuja en lugar del que falló,
      // sin ancestro de texto, así que Flutter aplicaba `_errorTextStyle`
      // (subrayado amarillo doble) a todos los textos.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: AppErrorSurface(message: 'boom'),
        ),
      );

      // Hay un Material/DefaultTextStyle que define el estilo por defecto.
      // Los finders se acotan al subárbol de `AppErrorSurface` porque la raíz
      // de `pumpWidget` también injecta sus propios `DefaultTextStyle`.
      final surface = find.byType(AppErrorSurface);
      expect(
        find.descendant(of: surface, matching: find.byType(Material)),
        findsOneWidget,
      );
      // Ojo: son varios, porque `Material` mete un `AnimatedDefaultTextStyle`
      // propio además del ours. Todos deben salir sin subrayado.
      final defaultStyles = tester.widgetList<DefaultTextStyle>(
        find.descendant(of: surface, matching: find.byType(DefaultTextStyle)),
      );
      expect(defaultStyles, isNotEmpty);
      for (final style in defaultStyles) {
        expect(style.style.decoration, TextDecoration.none);
      }

      // Y ningún Text queda con subrayado.
      for (final text in tester.widgetList<Text>(
        find.descendant(of: surface, matching: find.byType(Text)),
      )) {
        expect(
          text.style?.decoration,
          TextDecoration.none,
          reason: 'el texto "${text.data}" no debe quedar subrayado',
        );
      }
    });
  });

  group('El estilo de error de MaterialApp (subrayado amarillo)', () {
    // `MaterialApp` configura su `WidgetsApp.textStyle` con `_errorTextStyle`
    // (material/app.dart): rojo, monoespaciado 48, subrayado AMARILLO doble.
    // Es deliberado: avisa que pusiste `Text` fuera de un `Material`/`Scaffold`.
    // Este test fija esa trampa para que no vuelva a sorprender.
    testWidgets('un Text suelto bajo MaterialApp hereda el estilo de error',
        (tester) async {
      TextStyle? inherited;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => _StyleProbe(
              onStyle: (style) => inherited = style,
            ),
          ),
        ),
      );

      expect(inherited, isNotNull);
      expect(inherited!.decoration, TextDecoration.underline);
      expect(inherited!.decorationStyle, TextDecorationStyle.double);
      expect(inherited!.decorationColor, const Color(0xFFFFFF00));
    });

    // Éste es el caso real: `ErrorWidget.builder` se dibuja *en lugar* del
    // widget que falló, dentro del árbol del MaterialApp y sin `Scaffold`.
    // Por eso `AppErrorSurface` se envuelve en su propio `Material` +
    // `DefaultTextStyle`: así ningún texto hereda `_errorTextStyle`.
    testWidgets('AppErrorSurface neutraliza el estilo de error de su host',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppErrorSurface(message: 'boom')),
      );

      final texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(
          text.style?.decoration,
          TextDecoration.none,
          reason: 'el texto "${text.data}" no debe heredar _errorTextStyle',
        );
      }

      expect(find.byType(AppErrorSurface), findsOneWidget);
    });
  });

  group('Cableado del contenedor de providers', () {
    testWidgets(
        'los overrides del contenedor raíz llegan incluso a lecturas indirectas',
        (tester) async {
      final container = ProviderContainer(
        overrides: [_handlerProvider.overrideWithValue(_FakeHandler('ok'))],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    Text('${ref.watch(_indirectProvider)}'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets(
        'un ProviderScope ANIDADO descarta los overrides (causa del bug)',
        (tester) async {
      // Contraejemplo del arrangement que había en `main()` antes del arreglo:
      // `runApp(ProviderScope(child: AppBootstrap()))` y adentro otro
      // `ProviderScope(overrides: [...])`. En Riverpod 2 el scope interno no
      // reparte sus overrides a los `Consumer` descendientes, así que
      // `audioHandlerProvider` ejecutaba su factory y tiraba
      // `UnimplementedError: audioHandlerProvider debe sobreescribirse`,
      // que `ErrorWidget.builder` pintaba como pantalla de error.
      //
      // Por eso `main()` ya no envuelve nada y `AppBootstrap` expone un único
      // `ProviderContainer` vía `UncontrolledProviderScope`.
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (_) => ProviderScope(
              overrides: [
                _handlerProvider.overrideWithValue(_FakeHandler('ok'))
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) =>
                        Text('${ref.watch(_indirectProvider)}'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<UnimplementedError>());
    });

    testWidgets('sin override, el error sigue siendo visible (falla rápido)',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) =>
                    Text('${ref.watch(_indirectProvider)}'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isA<UnimplementedError>());
    });
  });
}
