import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/app_bootstrap.dart';

void main() {
  // Se instala antes de nada para capturar errores de cualquier etapa,
  // incluidas las de arranque y las de build de widgets.
  WidgetsFlutterBinding.ensureInitialized();
  AppDiagnostics.install();

  // `AppBootstrap` monta la UI de inmediato (pantalla de carga o de error) y
  // recién después abre Hive, SharedPreferences, Dio y el handle de audio.
  // Así la app nunca queda mostrando sólo el fondo de arranque.
  runApp(const ProviderScope(child: AppBootstrap()));
}