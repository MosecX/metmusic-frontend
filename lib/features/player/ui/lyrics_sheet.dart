import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/lyrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_player_card.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';

/// Bottom sheet de letras (estilo Apple Music / Spotify).
///
/// El render sigue el contrato de `GET /api/lyrics/{trackId}` y se decide
/// SIEMPRE por `sync_level` (puede variar por track y por request):
///
/// - `word` → karaoke por palabra: cada palabra se pinta con
///   `time_ms + duration_ms` contra la posición del reproductor; si una
///   línea viene sin `words`, se resalta la línea completa.
/// - `line` → se resalta la línea actual
///   (`time_ms <= pos < time_ms + duration_ms` o hasta la siguiente).
/// - `none` → sólo texto plano, scroll manual, sin sincronía.
class LyricsSheet extends ConsumerStatefulWidget {
  const LyricsSheet({super.key});

  /// Muestra la hoja de letras.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => const LyricsSheet(),
    );
  }

  @override
  ConsumerState<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<LyricsSheet> {
  /// Claves por línea para centrarla con `Scrollable.ensureVisible`.
  final List<GlobalKey> _lineKeys = [];

  /// Última línea activa vista (para disparar el auto-scroll una sola vez).
  int _activeLine = -1;

  /// Momento del último arrastre del usuario: el auto-scroll respeta una
  /// pausa para no pelearse con el dedo.
  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _canAutoScroll =>
      DateTime.now().difference(_lastUserScroll) > const Duration(seconds: 3);

  void _syncLineKeys(int count) {
    while (_lineKeys.length < count) {
      _lineKeys.add(GlobalKey());
    }
    if (_lineKeys.length > count) {
      _lineKeys.removeRange(count, _lineKeys.length);
    }
  }

  void _scrollToLine(int index) {
    if (!mounted || index < 0 || index >= _lineKeys.length) return;
    if (!_canAutoScroll) return;
    final lineContext = _lineKeys[index].currentContext;
    if (lineContext == null) return;
    Scrollable.ensureVisible(
      lineContext,
      alignment: 0.3,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// Sólo el arrastre del usuario (`dragDetails != null`) pospone el
  /// auto-scroll; el scroll programático no lo hace.
  bool _handleScrollNotifications(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _lastUserScroll = DateTime.now();
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null) {
      _lastUserScroll = DateTime.now();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final trackId = state.track?.trackId ?? '';
    final position = ref.watch(playerProvider.select((s) => s.position));
    final lyricsAsync = ref.watch(lyricsProvider(trackId));

    final lyrics = lyricsAsync.valueOrNull;
    final level = lyrics?.level ?? LyricsSyncLevel.none;
    final lines = lyrics?.syncedLines ?? const <SyncedLine>[];
    final posMs = position.inMilliseconds;

    final activeIndex = (lyrics != null && level != LyricsSyncLevel.none)
        ? lyrics.activeLineIndex(posMs)
        : -1;
    if (activeIndex != _activeLine) {
      final previous = _activeLine;
      _activeLine = activeIndex;
      if (activeIndex >= 0 && activeIndex != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLine(activeIndex);
        });
      }
    }
    _syncLineKeys(lines.length);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
          ),
          child: GlassPlayerCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                const _SheetHandle(),
                _header(lyrics),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(
                    lyricsAsync: lyricsAsync,
                    trackId: trackId,
                    lyrics: lyrics,
                    lines: lines,
                    level: level,
                    activeIndex: activeIndex,
                    posMs: posMs,
                    scrollController: scrollController,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(Lyrics? lyrics) {
    final synced = lyrics != null &&
        lyrics.hasSynced &&
        lyrics.level != LyricsSyncLevel.none;
    return Row(
      children: [
        const Icon(LucideIcons.captions, size: 18, color: AppColors.accent),
        const SizedBox(width: 8),
        const Text('Letras', style: AppTextStyles.title),
        if (synced) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.audioLines,
                  size: 12,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'SINCRONIZADAS',
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.accent,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }

  Widget _buildBody({
    required AsyncValue<Lyrics?> lyricsAsync,
    required String trackId,
    required Lyrics? lyrics,
    required List<SyncedLine> lines,
    required LyricsSyncLevel level,
    required int activeIndex,
    required int posMs,
    required ScrollController scrollController,
  }) {
    return lyricsAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
              strokeWidth: 2.6, color: AppColors.accent),
        ),
      ),
      error: (error, _) => EmptyState(
        icon: LucideIcons.captions,
        title: 'No se pudieron cargar las letras',
        subtitle: 'Revisá la conexión e intentá otra vez.',
        action: FilledButton(
          onPressed: () => ref.invalidate(lyricsProvider(trackId)),
          child: const Text('Reintentar'),
        ),
      ),
      data: (_) {
        if (lyrics == null || !lyrics.hasLyrics) {
          return const EmptyState(
            icon: LucideIcons.captions,
            title: 'Sin letras',
            subtitle: 'Todavía no hay letras para esta canción.',
          );
        }

        // `none` o sin líneas utilizables: sólo texto plano, scroll a mano.
        if (level == LyricsSyncLevel.none || lines.isEmpty) {
          final text = (lyrics.lyrics ?? '').trim().isNotEmpty
              ? lyrics.lyrics!
              : lines.map((l) => l.text).join('\n');
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
            child: Text(
              text,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 16,
                height: 1.6,
                color: AppColors.textPrimary.withValues(alpha: 0.75),
              ),
            ),
          );
        }

        // Sincronizadas: karaoke por palabra o por línea, con auto-scroll.
        return NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotifications,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 28),
            itemCount: lines.length,
            itemBuilder: (context, index) {
              final line = lines[index];
              final active = index == activeIndex;
              return Container(
                key: _lineKeys[index],
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text.rich(
                  _lineSpan(line, active: active, level: level, posMs: posMs),
                  style: _lineStyle(active),
                ),
              );
            },
          ),
        );
      },
    );
  }

  TextStyle _lineStyle(bool active) => TextStyle(
        fontSize: active ? 21 : 19,
        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.2,
        color: active ? AppColors.textPrimary : AppColors.textTertiary,
      );

  InlineSpan _lineSpan(
    SyncedLine line, {
    required bool active,
    required LyricsSyncLevel level,
    required int posMs,
  }) {
    // Nivel "line" o línea sin palabras (o nivel "none"): manda el color
    // de la línea entera.
    if (level != LyricsSyncLevel.word || line.words.isEmpty) {
      return TextSpan(text: line.text);
    }
    return TextSpan(
      children: [
        for (var i = 0; i < line.words.length; i++)
          TextSpan(
            text: line.words[i].text,
            style: TextStyle(color: _wordColor(line, i, active, posMs)),
          ),
      ],
    );
  }

  Color _wordColor(SyncedLine line, int index, bool active, int posMs) {
    if (!active) return AppColors.textTertiary;
    final start = line.words[index].timeMs;
    final end = line.wordEndMs(index);
    if (posMs >= start && (end == null || posMs < end)) {
      // Palabra que está sonando ahora.
      return AppColors.accent;
    }
    if (end != null && posMs >= end) {
      // Ya cantada.
      return AppColors.textPrimary;
    }
    // Falta cantar.
    return const Color(0x59FFFFFF);
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 2, bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.textDisabled,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
