import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/radio_mix.dart';
import '../../../core/network/api_exception.dart';
import '../../../services/service_providers.dart';

/// Pistas que respondieron **404** al pedir su radio en esta sesión.
///
/// El backend cachea esa respuesta 15 min, así que volver a preguntar sólo
/// repetiría el error: el menú de contexto deja de ofrecer la estación.
final radioUnsupportedProvider = StateProvider<Set<String>>(
  (ref) => const <String>{},
);

/// Estación que muestra la página `/mix/:trackId`.
///
/// El backend cachea la respuesta 15 min por pista, así que volver a entrar
/// es instantáneo; una pista sin radio cae en el error de la ruta.
final mixDetailProvider =
    FutureProvider.family<RadioStation, String>((ref, trackId) async {
  final station = await ref.watch(radioServiceProvider).getRadio(trackId);
  if (station == null) {
    throw const NotFoundApiException(
      'Esta pista no tiene estación',
      statusCode: 404,
    );
  }
  return station;
});
