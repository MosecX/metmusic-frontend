import '../utils/extensions.dart';

/// Una línea de letra sincronizada.
class SyncedLine {
  const SyncedLine({required this.timeMs, required this.text});

  final int timeMs;
  final String text;

  Duration get time => Duration(milliseconds: timeMs);

  factory SyncedLine.fromJson(Map<String, dynamic> json) {
    return SyncedLine(
      timeMs: Json.intOr(json['time_ms'] ?? json['time'] ?? json['start_ms'], 0),
      text: Json.strOr(json['text'] ?? json['line'] ?? json['value'], ''),
    );
  }

  Map<String, dynamic> toJson() => {'time_ms': timeMs, 'text': text};
}

/// Resultado de `GET /api/lyrics/{trackId}`.
class Lyrics {
  const Lyrics({
    this.lyrics,
    this.isSynced = false,
    this.syncedLines = const [],
    this.lrc,
    this.trackId,
  });

  final String? lyrics;
  final bool isSynced;
  final List<SyncedLine> syncedLines;
  final String? lrc;
  final String? trackId;

  bool get hasLyrics =>
      (lyrics != null && lyrics!.trim().isNotEmpty) || syncedLines.isNotEmpty;

  bool get hasSynced => isSynced && syncedLines.isNotEmpty;

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    var lines = Json.listAt(json, 'synced_lines')
        .map(SyncedLine.fromJson)
        .toList(growable: false);
    final lrc = Json.str(json['lrc']);
    final synced = Json.boolOr(json['is_synced'], false);
    if (lines.isEmpty && synced && lrc != null) {
      lines = _parseLrc(lrc);
    }
    return Lyrics(
      lyrics: Json.str(json['lyrics'] ?? json['plain_lyrics']),
      isSynced: synced || lines.isNotEmpty,
      syncedLines: lines..sort((a, b) => a.timeMs.compareTo(b.timeMs)),
      lrc: lrc,
      trackId: Json.str(json['track_id']),
    );
  }

  static List<SyncedLine> _parseLrc(String lrc) {
    final regex = RegExp(r'\[(\d+):(\d+)(?:[.:](\d+))?\](.*)');
    final result = <SyncedLine>[];
    for (final raw in lrc.split('\n')) {
      final m = regex.firstMatch(raw.trim());
      if (m == null) continue;
      final minutes = int.tryParse(m.group(1) ?? '0') ?? 0;
      final seconds = int.tryParse(m.group(2) ?? '0') ?? 0;
      final fractionRaw = m.group(3) ?? '0';
      final fraction = int.tryParse(fractionRaw) ?? 0;
      final ms = fractionRaw.length == 2 ? fraction * 10 : fraction;
      final text = (m.group(4) ?? '').trim();
      if (text.isEmpty) continue;
      result.add(
        SyncedLine(
          timeMs: minutes * 60000 + seconds * 1000 + ms,
          text: text,
        ),
      );
    }
    return result;
  }
}
