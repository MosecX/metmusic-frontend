import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/canvas.dart';
import '../../../services/service_providers.dart';

/// Canvas de un track (`GET /api/canvas/{trackId}`).
///
/// Devuelve `null` cuando el backend responde 404: en ese caso el player
/// muestra el artwork estático.
final canvasProvider =
    FutureProvider.family<CanvasMedia?, String>((ref, trackId) async {
  if (trackId.isEmpty) return null;
  return ref.watch(canvasServiceProvider).getCanvas(trackId);
});
