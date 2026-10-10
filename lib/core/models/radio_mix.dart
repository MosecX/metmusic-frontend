import '../utils/extensions.dart';
import 'track.dart';

/// Metadatos de la estación (mix) devuelta por `GET /api/tracks/{id}/radio`.
class RadioMix {
  const RadioMix({
    required this.id,
    required this.title,
    this.subTitle,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String title;

  /// Artista principal de la estación (`sub_title` del payload).
  final String? subTitle;
  final String? description;

  /// Imagen firmada de Tidal. Si el backend la refresca cada 15 min, una
  /// URL vieja vuelve a funcionar re-pidiendo el radio.
  final String? imageUrl;

  factory RadioMix.fromJson(Map<String, dynamic> json) {
    return RadioMix(
      id: Json.strOr(json['id'], ''),
      title: Json.strOr(json['title'], ''),
      subTitle: Json.str(json['sub_title']),
      description: Json.str(json['description']),
      imageUrl: Json.str(json['image_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (subTitle != null) 'sub_title': subTitle,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

/// Respuesta de `GET /api/tracks/{trackId}/radio`.
///
/// Trae la estación y TODAS sus pistas de una (sin paginar; el backend
/// cachea 15 min por pista). El primer item es la pista semilla con la que
/// se pidió el radio.
class RadioStation {
  const RadioStation({
    required this.trackId,
    required this.mix,
    required this.items,
  });

  final String trackId;
  final RadioMix mix;
  final List<Track> items;

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      trackId: Json.strOr(json['track_id'], ''),
      mix: RadioMix.fromJson(Json.mapOf(json['mix'])),
      items: Json.listAt(json, 'items')
          .map(Track.fromJson)
          .toList(growable: false),
    );
  }
}
