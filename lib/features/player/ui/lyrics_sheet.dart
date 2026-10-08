import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/lyrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/lyrics_timeline.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/player_state.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';
import 'lyrics/lyrics_gap.dart';
import 'lyrics/lyrics_line.dart';

/// Ancla vertical del scroll: la línea que importa queda al 18 % del
/// viewport (am-lyrics `--lyrics-scroll-padding-top`), no centrada.
const double _kScrollAnchor = 0.18;

/// Tipo de fila del listado de la hoja.
enum _RowKind { line, gap, footer }

/// Fila de la lista: una línea, un hueco instrumental o el pie. Mezclarlos
/// en un solo listado permite animar los huecos sin inventar líneas falsas.
class _LyricsRow {
  const _LyricsRow.line(this.index)
      : kind = _RowKind.line,
        gap = null;

  const _LyricsRow.gap(this.gap)
      : kind = _RowKind.gap,
        index = -1;

  const _LyricsRow.footer()
      : kind = _RowKind.footer,
        index = -1,
        gap = null;

  final _RowKind kind;

  /// Índice en `Lyrics.syncedLines` (sólo para [_RowKind.line]).
  final int index;
  final LyricsGap? gap;
}

/// Hoja de letras a pantalla completa con dos modos de presentación
/// (configurable en Ajustes y conmutable desde el encabezado):
///
///  - `standard`   : letras sincronizadas limpias sobre el artwork
///                   desenfocado, alineadas a la izquierda.
///  - `visualizer` : fondo animado (Ken-Burns sobre el artwork) y líneas con
///                   resplandor, con soporte de horizontal.
///
/// El render se decide por `sync_level` de la API (puede variar por track):
/// `word` → wipe por palabra con borde suave; `line` → resalta la línea
/// actual; `none` → texto plano con scroll manual.
///
/// El comportamiento sigue a am-lyrics: escalera de opacidad/escala por
/// distancia (0.8 → 0.46 y 0.98), scroll predictivo 350-500 ms antes del
/// próximo verso anclado al 18 % del viewport, y puntos respirando en los
/// huecos instrumentales de 7 s o más. El tamaño de caja de cada línea
/// nunca cambia: no hay zoom ni reflow.
class LyricsSheet extends ConsumerStatefulWidget {
  const LyricsSheet({super.key});

  /// Muestra la hoja de letras a pantalla completa.
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

class _LyricsSheetState extends ConsumerState<LyricsSheet>
    with SingleTickerProviderStateMixin {
  /// Claves por fila para llevarla al ancla con el auto-scroll.
  final List<GlobalKey> _rowKeys = [];

  /// Fila de cada línea (`índice de línea → índice de fila`), porque los
  /// huecos y el pie desplazan los índices.
  final List<int> _lineRow = [];

  /// Última fila objetivo del scroll (para dispararlo una sola vez).
  int _targetRow = -1;

  /// Momento del último arrastre del usuario: el auto-scroll respeta una
  /// pausa para no pelearse con el dedo.
  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);

  /// Altura medida de una fila (para estimar el scroll de filas lejanas).
  double? _measuredItemHeight;

  /// Controlador del `DraggableScrollableSheet` (la lista usa el mismo).
  ScrollController? _sheetController;

  /// Ticker del fondo animado del modo visualizer (creado sólo si se usa).
  AnimationController? _visualizerBg;

  bool get _canAutoScroll =>
      DateTime.now().difference(_lastUserScroll) > const Duration(seconds: 3);

  void _syncRowKeys(int count) {
    while (_rowKeys.length < count) {
      _rowKeys.add(GlobalKey());
    }
    if (_rowKeys.length > count) {
      _rowKeys.removeRange(count, _rowKeys.length);
    }
  }

  /// Intercala huecos y pie alrededor de las líneas. Sólo tiene sentido
  /// con letras sincronizadas.
  List<_LyricsRow> _buildRows(
    List<SyncedLine> lines,
    Lyrics? lyrics,
    int songEndMs,
  ) {
    final rows = <_LyricsRow>[];
    if (lines.isEmpty) return rows;
    final gaps = instrumentalGaps(
      lines,
      songEndMs: songEndMs > 0 ? songEndMs : null,
    );
    var gapIndex = 0;
    for (var i = 0; i <= lines.length; i++) {
      if (gapIndex < gaps.length && gaps[gapIndex].beforeIndex == i) {
        rows.add(_LyricsRow.gap(gaps[gapIndex]));
        gapIndex++;
      }
      if (i < lines.length) {
        _lineRow.add(rows.length);
        rows.add(_LyricsRow.line(i));
      }
    }
    rows.add(const _LyricsRow.footer());
    return rows;
  }

  /// Lleva la fila [row] al ancla del 18 % del viewport. Si la fila todavía
  /// no se construyó (lista perezosa), estima el offset y reintenta el
  /// siguiente frame, como en el player de referencia.
  void _scrollToRow(int row, {required Duration duration, int attempt = 0}) {
    if (!mounted || row < 0 || row >= _rowKeys.length) return;
    if (!_canAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canAutoScroll) return;
      final controller = _sheetController;
      if (controller == null || !controller.hasClients) return;
      final position = controller.position;
      final anchor = position.viewportDimension * _kScrollAnchor;

      final rowContext = _rowKeys[row].currentContext;
      if (rowContext != null) {
        final rowBox = rowContext.findRenderObject() as RenderBox?;
        final scrollBox =
            position.context.storageContext.findRenderObject() as RenderBox?;
        if (rowBox != null && scrollBox != null && rowBox.size.height > 0) {
          _measuredItemHeight ??= rowBox.size.height;
          final rowOffset = rowBox.localToGlobal(Offset.zero).dy -
              scrollBox.localToGlobal(Offset.zero).dy +
              controller.offset;
          controller.animateTo(
            (rowOffset - anchor).clamp(0.0, position.maxScrollExtent),
            duration: duration,
            curve: Curves.easeOutCubic,
          );
          return;
        }
      }
      if (attempt >= 40) return;
      final itemHeight = _measuredItemHeight ?? 64;
      final estimated = (row * itemHeight) - anchor;
      controller.jumpTo(estimated.clamp(0.0, position.maxScrollExtent));
      _scrollToRow(row, duration: duration, attempt: attempt + 1);
    });
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

  /// Salta el reproductor al inicio de la línea tocada.
  void _seekToLine(SyncedLine line) {
    ref.read(playerProvider.notifier).seek(Duration(milliseconds: line.timeMs));
  }

  AnimationController _ensureVisualizerBg() {
    return _visualizerBg ??=
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
  }

  @override
  void dispose() {
    _visualizerBg?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final state = ref.watch(playerProvider);
    final positionMs =
        ref.watch(playerProvider.select((s) => s.position)).inMilliseconds;
    final trackId = state.track?.trackId ?? '';
    final lyricsAsync = ref.watch(lyricsProvider(trackId));

    final lyrics = lyricsAsync.valueOrNull;
    final level = lyrics?.level ?? LyricsSyncLevel.none;
    final lines = lyrics?.syncedLines ?? const <SyncedLine>[];
    final synced =
        lyrics != null && lyrics.hasSynced && level != LyricsSyncLevel.none;

    // Las claves deben existir ANTES de programar el scroll a la fila
    // objetivo (al abrir a media canción la lista es perezosa y se estima).
    _lineRow.clear();
    final rows = synced
        ? _buildRows(lines, lyrics, state.duration.inMilliseconds)
        : const <_LyricsRow>[];
    _syncRowKeys(rows.length);

    // `activeLineIndex` sólo se enciende mientras la línea suena; en los
    // huecos instrumentales devuelve -1 y manda la línea ancla.
    final litIndex = synced ? lyrics.activeLineIndex(positionMs) : -1;
    final anchorIndex = synced ? lyricsAnchorIndex(lines, positionMs) : -1;

    final target = synced
        ? predictiveScrollTarget(lines, anchorIndex, positionMs)
        : null;
    if (target != null && target.line < _lineRow.length) {
      final row = _lineRow[target.line];
      if (row != _targetRow) {
        _targetRow = row;
        _scrollToRow(row, duration: target.duration);
      }
    }

    // El fondo animado sólo corre en modo visualizer.
    final visualizer = settings.lyricsMode == LyricsMode.visualizer;
    if (visualizer) {
      _ensureVisualizerBg();
    } else {
      _visualizerBg?.stop();
    }

    return DraggableScrollableSheet(
      initialChildSize: 1,
      minChildSize: 0.4,
      maxChildSize: 1,
      snap: true,
      snapSizes: const [0.7, 1],
      builder: (context, scrollController) {
        _sheetController = scrollController;
        return _lyricsScrollView(
          state: state,
          lyrics: lyrics,
          lines: lines,
          level: level,
          synced: synced,
          rows: rows,
          litIndex: litIndex,
          anchorIndex: anchorIndex,
          positionMs: positionMs,
          lyricsAsync: lyricsAsync,
          scrollController: scrollController,
          visualizer: visualizer,
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Lista común (el fondo depende del modo)
  // -------------------------------------------------------------------------

  Widget _lyricsScrollView({
    required MetPlayerState state,
    required Lyrics? lyrics,
    required List<SyncedLine> lines,
    required LyricsSyncLevel level,
    required bool synced,
    required List<_LyricsRow> rows,
    required int litIndex,
    required int anchorIndex,
    required int positionMs,
    required AsyncValue<Lyrics?> lyricsAsync,
    required ScrollController scrollController,
    required bool visualizer,
  }) {
    final artwork = state.artworkUrl;
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final hasText = lyrics != null && lyrics.hasLyrics;
    // `none` (o líneas no utilizables): sólo texto plano, scroll a mano.
    final plainOnly = level == LyricsSyncLevel.none || lines.isEmpty;
    final loading = lyricsAsync.isLoading;

    final Widget list = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotifications,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _header(synced: synced, landscape: landscape),
          ),
          if (loading)
            SliverToBoxAdapter(
              child: _loadingSkeleton(landscape: landscape),
            )
          else if (!hasText)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No hay letra disponible.',
                  style: AppTextStyles.subtitle,
                ),
              ),
            )
          else if (plainOnly)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                landscape ? 48 : 28,
                0,
                landscape ? 48 : 24,
                MediaQuery.paddingOf(context).bottom + 120,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _plainText(lyrics, lines),
                  textAlign: landscape ? TextAlign.center : TextAlign.left,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 17,
                    height: 1.7,
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                landscape ? 48 : 24,
                0,
                landscape ? 48 : 24,
                MediaQuery.paddingOf(context).bottom + 120,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, rowIndex) {
                  return _buildRow(
                    rows[rowIndex],
                    lines: lines,
                    lyrics: lyrics,
                    level: level,
                    litIndex: litIndex,
                    anchorIndex: anchorIndex,
                    positionMs: positionMs,
                    visualizer: visualizer,
                    landscape: landscape,
                    rowKey: _rowKeys[rowIndex],
                  );
                }, childCount: rows.length),
              ),
            ),
        ],
      ),
    );

    if (!visualizer) {
      // Modo estándar: fondo = artwork desenfocado + velo oscuro.
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.background),
          if (artwork.isNotEmpty)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
              child: Transform.scale(
                scale: 1.15,
                child: CachedNetworkImage(
                  imageUrl: artwork,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: AppColors.background),
                ),
              ),
            ),
          const ColoredBox(color: Color(0xCC000000)),
          list,
        ],
      );
    }

    // Modo visualizer: fondo animado + velo.
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        _VisualizerBackdrop(
          artwork: artwork,
          controller: _ensureVisualizerBg(),
        ),
        const ColoredBox(color: Color(0x99000000)),
        list,
      ],
    );
  }

  Widget _buildRow(
    _LyricsRow row, {
    required List<SyncedLine> lines,
    required Lyrics? lyrics,
    required LyricsSyncLevel level,
    required int litIndex,
    required int anchorIndex,
    required int positionMs,
    required bool visualizer,
    required bool landscape,
    required Key rowKey,
  }) {
    switch (row.kind) {
      case _RowKind.gap:
        return LyricsGapDots(
          key: rowKey,
          gap: row.gap!,
          positionMs: positionMs,
        );
      case _RowKind.footer:
        return KeyedSubtree(
          key: rowKey,
          child: _footer(lyrics!, level),
        );
      case _RowKind.line:
        final line = lines[row.index];
        final lit = row.index == litIndex;
        return LyricsLine(
          key: rowKey,
          line: line,
          lit: lit,
          distance: lyricsDistance(row.index, anchorIndex, lit: lit),
          level: level,
          positionMs: positionMs,
          visualizer: visualizer,
          landscape: landscape,
          onTap: () => _seekToLine(line),
        );
    }
  }

  String _plainText(Lyrics? lyrics, List<SyncedLine> lines) {
    final plain = (lyrics?.lyrics ?? '').trim();
    if (plain.isNotEmpty) return plain;
    return lines.map((l) => l.text).join('\n');
  }

  // -------------------------------------------------------------------------
  // Encabezado / pie / carga
  // -------------------------------------------------------------------------

  Widget _header({required bool synced, required bool landscape}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        landscape ? 40 : 28,
        MediaQuery.paddingOf(context).top + 22,
        landscape ? 40 : 20,
        26,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 14),
          const Text('Letra', style: AppTextStyles.headline),
          const Spacer(),
          if (synced) ...[
            _syncedChip(),
            const SizedBox(width: 4),
          ],
          _modeToggle(),
        ],
      ),
    );
  }

  Widget _syncedChip() {
    return Container(
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
    );
  }

  /// Alterna entre estándar y visualizer (misma preferencia que Ajustes).
  Widget _modeToggle() {
    final currentMode = ref.watch(settingsProvider.select((s) => s.lyricsMode));
    final visualizerMode = currentMode == LyricsMode.visualizer;
    return IconButton(
      tooltip: visualizerMode ? 'Modo estándar' : 'Modo visualizer',
      onPressed: () {
        ref.read(settingsProvider.notifier).setLyricsMode(
              visualizerMode ? LyricsMode.standard : LyricsMode.visualizer,
            );
      },
      icon: Icon(
        visualizerMode ? LucideIcons.captions : LucideIcons.sparkles,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Pie: nivel de sincronía del track y quién lo sirvió.
  Widget _footer(Lyrics lyrics, LyricsSyncLevel level) {
    final provider = lyrics.provider ?? 'desconocida';
    final source = lyrics.source;
    final label = level == LyricsSyncLevel.word ? 'PALABRA' : 'LÍNEA';
    final detail = source == null || source.isEmpty
        ? 'Fuente · $provider'
        : 'Fuente · $provider · $source';
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  /// Esqueleto de carga (am-lyrics): barras shimmer en vez de un spinner.
  Widget _loadingSkeleton({required bool landscape}) {
    const widths = [230.0, 168.0, 300.0, 146.0, 264.0, 190.0];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        landscape ? 48 : 24,
        24,
        landscape ? 48 : 24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in widths) ...[
            ShimmerBox(width: width, height: 20, borderRadius: 6),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo animado del visualizer
// ---------------------------------------------------------------------------

/// Fondo del visualizer: una copia desenfocada del artwork que deriva,
/// escala (Ken-Burns) y rota con movimiento lento y claramente visible. El
/// desenfoque se rasteriza UNA vez y se cachea; sólo corren las
/// transformaciones baratas de GPU por frame.
class _VisualizerBackdrop extends StatelessWidget {
  const _VisualizerBackdrop({
    required this.artwork,
    required this.controller,
  });

  final String artwork;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final a = 2 * pi * t;
        final scaleX = 3.0 + 0.8 * sin(a);
        final scaleY = 2.9 + 0.8 * sin(a * 1.3 + 0.8);
        final dx = size.width * 0.45 * sin(a);
        final dy = size.height * 0.40 * cos(a * 0.73);
        final angle = 0.20 * sin(a * 0.7);
        Widget image = artwork.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: artwork,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: AppColors.backgroundAlt),
              )
            : const ColoredBox(color: AppColors.backgroundAlt);
        image = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: image,
        );
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              child: image,
            ),
          ),
        );
      },
    );
  }
}
