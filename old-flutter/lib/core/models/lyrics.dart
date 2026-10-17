import '../utils/extensions.dart';

/// Nivel de sincronía reportado por el backend (`sync_level`).
///
/// Es el campo que decide CÓMO renderizar y puede variar por track y por
/// request (depende de qué fuente gana): nunca se asume fijo, se lee
/// siempre de la respuesta.
enum LyricsSyncLevel {
  /// Karaoke por palabra (`words` con `time_ms` + `duration_ms`).
  word,

  /// Resalta la línea actual.
  line,

  /// Sólo texto plano, sin sincronía.
  none,
}

/// Una palabra de una línea con sincronía a nivel de palabra.
class SyncedWord {
  const SyncedWord({required this.timeMs, required this.text, this.durationMs});

  final int timeMs;
  final int? durationMs;
  final String text;

  Duration get time => Duration(milliseconds: timeMs);

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);

  factory SyncedWord.fromJson(Map<String, dynamic> json) {
    return SyncedWord(
      timeMs: Json.intOr(json['time_ms'], 0),
      durationMs: Json.asInt(json['duration_ms']),
      text: Json.strOr(json['text'], ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'time_ms': timeMs,
        if (durationMs != null) 'duration_ms': durationMs,
        'text': text,
      };
}

/// Una línea de letra sincronizada.
class SyncedLine {
  const SyncedLine({
    required this.timeMs,
    required this.text,
    this.durationMs,
    this.words = const [],
  });

  final int timeMs;

  /// Duración opcional: si es `null` la línea llega hasta la siguiente.
  final int? durationMs;
  final String text;

  /// Palabras individuales; sólo viene con `sync_level: word`.
  final List<SyncedWord> words;

  Duration get time => Duration(milliseconds: timeMs);

  /// Fin teórico de la línea (`time_ms + duration_ms`) o `null` si la
  /// duración no viene informada.
  int? get endMs => durationMs == null ? null : timeMs + durationMs!;

  /// Fin de la palabra [index] dentro de la línea: `duration_ms` manda; si
  /// no viene, el inicio de la siguiente palabra; si es la última, el fin
  /// de la línea (o `null` si tampoco hay: abierta).
  int? wordEndMs(int index) {
    if (index < 0 || index >= words.length) return null;
    final word = words[index];
    if (word.durationMs != null) return word.timeMs + word.durationMs!;
    if (index + 1 < words.length) return words[index + 1].timeMs;
    return endMs;
  }

  factory SyncedLine.fromJson(Map<String, dynamic> json) {
    return SyncedLine(
      timeMs:
          Json.intOr(json['time_ms'] ?? json['time'] ?? json['start_ms'], 0),
      durationMs: Json.asInt(json['duration_ms']),
      text: Json.strOr(json['text'] ?? json['line'] ?? json['value'], ''),
      words: Json.listAt(json, 'words')
          .map(SyncedWord.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'time_ms': timeMs,
        if (durationMs != null) 'duration_ms': durationMs,
        'text': text,
        if (words.isNotEmpty)
          'words': words.map((w) => w.toJson()).toList(growable: false),
      };
}

/// Resultado de `GET /api/lyrics/{trackId}`.
class Lyrics {
  const Lyrics({
    this.lyrics,
    this.isSynced = false,
    this.syncedLines = const [],
    this.lrc,
    this.trackId,
    this.syncLevel,
    this.provider,
    this.source,
  });

  /// Texto plano. Siempre presente en el contrato; única fuente cuando
  /// [level] es [LyricsSyncLevel.none].
  final String? lyrics;

  /// `sync_level !== "none"` (compatibilidad; redundante con [level]).
  final bool isSynced;

  /// Líneas ordenadas por `time_ms`. Las líneas vacías (silencios) se
  /// filtran en el parseo.
  final List<SyncedLine> syncedLines;
  final String? lrc;
  final String? trackId;

  /// Valor crudo de `sync_level` (`word` | `line` | `none`).
  final String? syncLevel;

  /// Fuente diagnóstica (`lyricsplus` | `spotycovs` | `lrclib`).
  final String? provider;

  /// Fuente upstream real (qApple, Spotify…). Informativo.
  final String? source;

  bool get hasLyrics =>
      (lyrics != null && lyrics!.trim().isNotEmpty) || syncedLines.isNotEmpty;

  bool get hasSynced => isSynced && syncedLines.isNotEmpty;

  /// Nivel de sincronía que manda para el render. Se lee de la respuesta;
  /// si un payload viejo no lo trae, se infiere de los datos.
  LyricsSyncLevel get level {
    switch ((syncLevel ?? '').toLowerCase()) {
      case 'word':
        return LyricsSyncLevel.word;
      case 'line':
        return LyricsSyncLevel.line;
      case 'none':
        return LyricsSyncLevel.none;
    }
    if (syncedLines.any((line) => line.words.isNotEmpty)) {
      return LyricsSyncLevel.word;
    }
    if (syncedLines.isNotEmpty || isSynced) return LyricsSyncLevel.line;
    return LyricsSyncLevel.none;
  }

  /// Índice de la línea que suena en [posMs], según el contrato:
  /// `time_ms <= pos < time_ms + duration_ms` (o hasta la siguiente línea
  /// si `duration_ms` es `null`). Devuelve -1 antes del primer verso o en
  /// los silencios entre líneas con duración.
  int activeLineIndex(int posMs) {
    final lines = syncedLines;
    var index = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].timeMs > posMs) break;
      index = i;
    }
    if (index < 0) return -1;
    final line = lines[index];
    final nextStart = index + 1 < lines.length ? lines[index + 1].timeMs : null;
    final end = line.endMs ?? nextStart;
    if (end != null && posMs >= end) return -1;
    return index;
  }

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    final rawLevel = Json.str(json['sync_level'])?.toLowerCase();
    var lines = Json.listAt(json, 'synced_lines')
        .map(SyncedLine.fromJson)
        .toList(growable: true);
    final lrc = Json.str(json['lrc']);
    final synced = Json.boolOr(
      json['is_synced'],
      rawLevel != null && rawLevel != 'none',
    );
    // El LRC sólo se usa como respaldo de compatibilidad: con
    // `sync_level: none` no se derivan tiempos (suele venir null igual).
    if (lines.isEmpty && synced && lrc != null && rawLevel != 'none') {
      lines = _parseLrc(lrc);
    }
    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    // Las líneas de texto vacío son silencios: no aportan al render.
    final visible =
        lines.where((l) => l.text.trim().isNotEmpty).toList(growable: false);
    return Lyrics(
      lyrics: Json.str(json['lyrics'] ?? json['plain_lyrics']),
      isSynced: synced || visible.isNotEmpty,
      syncedLines: visible,
      lrc: lrc,
      trackId: Json.str(json['track_id']),
      syncLevel: rawLevel,
      provider: Json.str(json['provider']),
      source: Json.str(json['source']),
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
