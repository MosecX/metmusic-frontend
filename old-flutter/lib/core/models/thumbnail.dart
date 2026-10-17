import '../utils/extensions.dart';

/// Una imagen disponible para un recurso (track, álbum, artista, playlist).
class Thumbnail {
  const Thumbnail({required this.url, this.width, this.height});

  final String url;
  final int? width;
  final int? height;

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      url: Json.strOr(json['url'], ''),
      width: Json.asInt(json['width']),
      height: Json.asInt(json['height']),
    );
  }

  /// Tolerante: acepta `[{url,width,height}]` o `["url", ...]`.
  static List<Thumbnail> listFrom(dynamic value) {
    if (value is! List) return const [];
    return value
        .map<Thumbnail?>((e) {
          if (e is Map) return Thumbnail.fromJson(Map<String, dynamic>.from(e));
          if (e is String && e.isNotEmpty) return Thumbnail(url: e);
          return null;
        })
        .whereType<Thumbnail>()
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  @override
  bool operator ==(Object other) =>
      other is Thumbnail && other.url == url && other.width == width;

  @override
  int get hashCode => Object.hash(url, width);
}
