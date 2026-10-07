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
import '../../settings/providers/settings_provider.dart';
import '../models/player_state.dart';
import '../providers/lyrics_provider.dart';
import '../providers/player_provider.dart';

/// Hoja de letras con dos modos de presentación (configurable en Ajustes y
/// conmutable desde el encabezado):
///
///  - `standard`   : letras sincronizadas limpias sobre el artwork
///                   desenfocado, alineadas a la izquierda.
///  - `visualizer` : fondo animado (Ken-Burns sobre el artwork) y líneas con
///                   resplandor, con soporte de horizontal.
///
/// El render se decide por `sync_level` de la API (puede variar por track):
/// `word` → karaoke por palabra con color; `line` → resalta la línea actual;
/// `none` → texto plano con scroll manual.
///
/// En NINGÚN modo la línea activa cambia de tamaño (sin zoom): la
/// distinción es sólo por color, peso y resplandor.

/// Distancia (en líneas) a la línea activa → sigma de desenfoque. La línea
/// activa sale nítida y los vecinos se desenfocan suave, para que las
/// líneas "emergen" de las borrosas al acercarse. Barato: tope en 8.
double _lineBlur(int distance, {double intensity = 1.0}) {
  if (distance <= 0) return 0;
  return (2.0 + (distance - 1) * 1.4).clamp(0.0, 8.0) * intensity;
}

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
  /// Claves por línea para centrarla con el auto-scroll.
  final List<GlobalKey> _lineKeys = [];

  /// Última línea activa vista (para disparar el auto-scroll una sola vez).
  int _activeLine = -1;

  /// Momento del último arrastre del usuario: el auto-scroll respeta una
  /// pausa para no pelearse con el dedo.
  DateTime _lastUserScroll = DateTime.fromMillisecondsSinceEpoch(0);

  /// Altura medida de una línea (para estimar el scroll de líneas lejanas).
  double? _measuredItemHeight;

  /// Controlador del `DraggableScrollableSheet` (la lista usa el mismo).
  ScrollController? _sheetController;

  /// Ticker del fondo animado del modo visualizer (creado sólo si se usa).
  AnimationController? _visualizerBg;

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

  /// Centra la línea [index] en el viewport. Si la línea todavía no se
  /// construyó (lista perezosa), estima el offset y reintenta el siguiente
  /// frame, como en el player de referencia.
  void _scrollToLine(int index, [int attempt = 0]) {
    if (!mounted || index < 0 || index >= _lineKeys.length) return;
    if (!_canAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_canAutoScroll) return;
      final controller = _sheetController;
      if (controller == null || !controller.hasClients) return;
      final position = controller.position;

      final lineContext = _lineKeys[index].currentContext;
      if (lineContext != null) {
        final lineBox = lineContext.findRenderObject() as RenderBox?;
        final scrollBox =
            position.context.storageContext.findRenderObject() as RenderBox?;
        if (lineBox != null && scrollBox != null && lineBox.size.height > 0) {
          _measuredItemHeight ??= lineBox.size.height;
          final lineOffset = lineBox.localToGlobal(Offset.zero).dy -
              scrollBox.localToGlobal(Offset.zero).dy +
              controller.offset;
          final target = lineOffset -
              (position.viewportDimension / 2) +
              (lineBox.size.height / 2);
          controller.animateTo(
            target.clamp(0.0, position.maxScrollExtent),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeInOutCubic,
          );
          return;
        }
      }
      if (attempt >= 40) return;
      final itemHeight = _measuredItemHeight ?? 64;
      final estimated = (index * itemHeight) -
          (position.viewportDimension / 2) +
          (itemHeight / 2);
      controller.jumpTo(estimated.clamp(0.0, position.maxScrollExtent));
      _scrollToLine(index, attempt + 1);
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

    // Las claves deben existir ANTES de programar el scroll a la línea
    // activa (al abrir a media canción la lista es perezosa y se estima).
    _syncLineKeys(lines.length);

    final activeIndex = synced ? lyrics.activeLineIndex(positionMs) : -1;
    if (activeIndex != _activeLine) {
      final previous = _activeLine;
      _activeLine = activeIndex;
      if (activeIndex >= 0 && activeIndex != previous) {
        _scrollToLine(activeIndex);
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
          activeIndex: activeIndex,
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
    required int activeIndex,
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

    final Widget list = NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotifications,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                landscape && visualizer ? 40 : 28,
                MediaQuery.paddingOf(context).top + 22,
                landscape && visualizer ? 40 : 20,
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
            ),
          ),
          if (!hasText)
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final line = lines[index];
                  final active = index == activeIndex;
                  final passed =
                      !active && activeIndex >= 0 && index < activeIndex;
                  final distance =
                      activeIndex < 0 ? 0 : (index - activeIndex).abs();
                  final span = _lineSpan(
                    line,
                    active: active,
                    level: level,
                    positionMs: positionMs,
                  );
                  if (visualizer) {
                    return _VisualizerLine(
                      key: _lineKeys[index],
                      span: span,
                      active: active,
                      passed: passed,
                      landscape: landscape,
                      blur: _lineBlur(distance),
                      onTap: () => _seekToLine(line),
                    );
                  }
                  return _StandardLine(
                    key: _lineKeys[index],
                    span: span,
                    active: active,
                    passed: passed,
                    blur: _lineBlur(distance, intensity: 0.4),
                    onTap: () => _seekToLine(line),
                  );
                }, childCount: lines.length),
              ),
            ),
        ],
      ),
    );

    if (lyricsAsync.isLoading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.accent,
          ),
        ),
      );
    }

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

  String _plainText(Lyrics? lyrics, List<SyncedLine> lines) {
    final plain = (lyrics?.lyrics ?? '').trim();
    if (plain.isNotEmpty) return plain;
    return lines.map((l) => l.text).join('\n');
  }

  // -------------------------------------------------------------------------
  // Encabezado / spans
  // -------------------------------------------------------------------------

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

  /// Span de la línea. Con `sync_level: word` y la línea activa, cada
  /// palabra se colorea según `time_ms + duration_ms` (karaoke por color,
  /// sin cambiar el tamaño). Si la línea viene sin palabras, manda el color
  /// de la línea entera.
  InlineSpan _lineSpan(
    SyncedLine line, {
    required bool active,
    required LyricsSyncLevel level,
    required int positionMs,
  }) {
    if (!active || level != LyricsSyncLevel.word || line.words.isEmpty) {
      return TextSpan(text: line.text);
    }
    return TextSpan(
      children: [
        for (var i = 0; i < line.words.length; i++)
          TextSpan(
            text: line.words[i].text,
            style: TextStyle(color: _wordColor(line, i, positionMs)),
          ),
      ],
    );
  }

  Color _wordColor(SyncedLine line, int index, int positionMs) {
    final start = line.words[index].timeMs;
    final end = line.wordEndMs(index);
    if (positionMs >= start && (end == null || positionMs < end)) {
      // Palabra que está sonando ahora.
      return AppColors.accent;
    }
    if (end != null && positionMs >= end) {
      // Ya cantada.
      return AppColors.textPrimary;
    }
    // Falta cantar.
    return const Color(0x8CFFFFFF);
  }
}

// ---------------------------------------------------------------------------
// Líneas
// ---------------------------------------------------------------------------

/// Línea del modo estándar: color y resplandor cambian con animación, el
/// tamaño NUNCA (sin zoom).
class _StandardLine extends StatelessWidget {
  const _StandardLine({
    required super.key,
    required this.span,
    required this.active,
    required this.passed,
    required this.blur,
    required this.onTap,
  });

  final InlineSpan span;
  final bool active;
  final bool passed;
  final double blur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: EdgeInsets.symmetric(vertical: active ? 7 : 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            style: TextStyle(
              color: active
                  ? AppColors.textPrimary
                  : (passed ? AppColors.textDisabled : AppColors.textSecondary),
              fontSize: 22,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.34,
              shadows: active
                  ? [
                      Shadow(
                        blurRadius: 14,
                        color: AppColors.textPrimary.withValues(alpha: 0.18),
                      ),
                      Shadow(
                        blurRadius: 26,
                        color: AppColors.accent.withValues(alpha: 0.16),
                      ),
                    ]
                  : null,
            ),
            child: Text.rich(span, textAlign: TextAlign.left),
          ),
        ),
      ),
    );
  }
}

/// Línea del modo visualizer: mismo esquema sin zoom, con resplandor más
/// marcado y texto centrado en horizontal.
class _VisualizerLine extends StatelessWidget {
  const _VisualizerLine({
    required super.key,
    required this.span,
    required this.active,
    required this.passed,
    required this.landscape,
    required this.blur,
    required this.onTap,
  });

  final InlineSpan span;
  final bool active;
  final bool passed;
  final bool landscape;
  final double blur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(vertical: active ? 9 : 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            textAlign: landscape ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: active
                  ? AppColors.textPrimary
                  : (passed ? AppColors.textDisabled : AppColors.textSecondary),
              fontSize: landscape ? 30 : 25,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: active ? 0.4 : 0,
              height: 1.36,
              shadows: active
                  ? [
                      Shadow(
                        blurRadius: 16,
                        color: AppColors.textPrimary.withValues(alpha: 0.22),
                      ),
                      Shadow(
                        blurRadius: 30,
                        color: AppColors.accent.withValues(alpha: 0.28),
                      ),
                    ]
                  : null,
            ),
            child: Text.rich(span),
          ),
        ),
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
