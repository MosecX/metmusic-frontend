import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pistas que respondieron **404** al pedir su radio en esta sesión.
///
/// El backend cachea esa respuesta 15 min, así que volver a preguntar sólo
/// repetiría el error: el menú de contexto deja de ofrecer la estación.
final radioUnsupportedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);
