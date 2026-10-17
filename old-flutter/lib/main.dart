import 'package:flutter/material.dart';

import 'bootstrap/app_bootstrap.dart';

void main() {
  // Se instala antes de nada para capturar errores de cualquier etapa,
  // incluidas las de arranque y las de build de widgets.
  WidgetsFlutterBinding.ensureInitialized();
  AppDiagnostics.install();

  // `AppBootstrap` monta la UI de inmediato (pantalla de carga o de error) y
  // recién después abre Hive, SharedPreferences, Dio y el handle de audio.
  // Así la app nunca queda mostrando sólo el fondo de arranque.
  //
  // El contenedor de Riverpod se crea dentro de `AppBootstrap` (con los
  // overrides) y se expone con `UncontrolledProviderScope`: no hay un
  // `ProviderScope` raíz sin overrides que pueda quedar conectado por error.
  runApp(const AppBootstrap());
}
