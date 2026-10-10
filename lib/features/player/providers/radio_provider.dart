import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/radio_mix.dart';
import '../../../core/network/api_exception.dart';
import '../../../services/local/mix_favorites_service.dart';
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

// ---------------------------------------------------------------------------
// Favoritos de mixes (sólo local, Hive — no se sincronizan con el backend)
// ---------------------------------------------------------------------------

/// Controlador de mixes guardados en el teléfono.
class MixFavoritesController extends Notifier<List<SavedMix>> {
  @override
  List<SavedMix> build() => ref.read(mixFavoritesServiceProvider).getAll();

  bool isFavorite(String trackId) =>
      state.any((saved) => saved.trackId == trackId);

  /// Alterna el mix en favoritos locales y devuelve el nuevo estado.
  Future<bool> toggle(String trackId, RadioMix mix) async {
    final service = ref.read(mixFavoritesServiceProvider);
    final nowFavorite = await service.toggle(trackId, mix);
    state = service.getAll();
    return nowFavorite;
  }
}

/// Mixes guardados en favoritos locales.
final mixFavoritesProvider =
    NotifierProvider<MixFavoritesController, List<SavedMix>>(
  MixFavoritesController.new,
);
