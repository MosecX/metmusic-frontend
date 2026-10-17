import '../utils/extensions.dart';
import 'track.dart';

/// Entrada del historial de reproducción (local o remota).
class HistoryEntry {
  const HistoryEntry({
    required this.trackId,
    required this.playedAt,
    this.playedMs = 0,
    this.completed = false,
    this.track,
  });

  final String trackId;
  final DateTime playedAt;
  final int playedMs;
  final bool completed;

  /// Metadatos embebidos (el backend puede devolverlos o no).
  final Track? track;

  String get title => track?.title ?? 'Track $trackId';
  String get artist => track?.artist ?? '';
  String get thumbnailUrl => track?.thumbnailUrl ?? '';

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawTrack = json['track'];
    final playedAtRaw =
        json['played_at'] ?? json['created_at'] ?? json['timestamp'];
    return HistoryEntry(
      trackId: Json.strOr(json['track_id'] ?? json['id'], ''),
      playedAt: _parseDate(playedAtRaw) ?? DateTime.now(),
      playedMs: Json.intOr(json['played_ms'], 0),
      completed: Json.boolOr(json['completed'], false),
      track: rawTrack is Map
          ? Track.fromJson(Map<String, dynamic>.from(rawTrack))
          : (json.containsKey('title') ? Track.fromJson(json) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'track_id': trackId,
        'played_ms': playedMs,
        'completed': completed,
        'played_at': playedAt.toIso8601String(),
        if (track != null) 'track': track!.toJson(),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // Época en segundos o milisegundos.
      return DateTime.fromMillisecondsSinceEpoch(
        value > 100000000000 ? value : value * 1000,
      );
    }
    return DateTime.tryParse(value.toString());
  }

  static List<HistoryEntry> listFrom(dynamic value) =>
      Json.maps(value).map(HistoryEntry.fromJson).toList(growable: false);
}
