import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_player_card.dart';
import '../../canvas/providers/canvas_provider.dart';
import '../../canvas/ui/canvas_overlay.dart';
import '../../playlist/ui/add_to_playlist_sheet.dart';
import '../models/player_state.dart';
import '../providers/player_provider.dart';
import 'player_artwork.dart';
import 'queue_sheet.dart';

/// Reproductor a pantalla completa (estilo Glass 1).
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  /// Valor del slider mientras el usuario arrastra.
  double? _dragValue;

  /// Desplazamiento vertical para el swipe-down.
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerProvider);
    final controller = ref.read(playerProvider.notifier);

    // Se mira siempre (aunque no haya track) para que la suscripción no cambie
    // entre builds: sin track el provider devuelve null y no se pinta nada.
    final trackId = state.track?.trackId ?? '';
    final canvasMedia = ref.watch(canvasProvider(trackId)).valueOrNull;
    final hasCanvas = canvasMedia != null;

    ref.listen(playerProvider.select((s) => s.track?.trackId), (_, next) {
      if (_dragValue != null) setState(() => _dragValue = null);
    });

    if (!state.hasTrack) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _Background(state: state),
            SafeArea(
              child: EmptyState(
                icon: LucideIcons.music,
                title: 'Nada en reproducción',
                subtitle: 'Elegí una canción para empezar.',
                action: FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Volver'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    // Estética Apple Music: la portada manda. Ocupa casi todo el ancho y se
    // encoge apenas al pausar, como el artwork flotante de iOS.
    final artworkSize = size.width * 0.78;

    // Si la canción tiene canvas animado, la portada ES el vídeo: se apila
    // sobre el artwork estático, que queda de base mientras carga o si el
    // track no lo tiene. Con canvas no se aplica el AnimatedScale del pausar,
    // porque un `Transform` sobre una `Texture` es lo que deforma los cuadros.
    //
    // No se envuelve en un ClipRRect: PlayerArtwork dibuja su propia sombra
    // hacia afuera y un clip la cortaría; el canvas ya se recorta solo con el
    // mismo radio.
    Widget artwork = SizedBox(
      width: artworkSize,
      height: artworkSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PlayerArtwork(
            url: state.artworkUrl,
            size: artworkSize,
            radius: 18,
            heroTag: AppConstants.heroArtworkTag,
            elevated: true,
          ),
          if (canvasMedia != null)
            CanvasOverlay(
              media: canvasMedia,
              playing: state.playing,
            ),
        ],
      ),
    );

    if (!hasCanvas) {
      artwork = AnimatedScale(
        scale: state.playing ? 1 : 0.9,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: artwork,
      );
    }

    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dy);
      },
      onVerticalDragEnd: (_) {
        if (_dragOffset > 90) {
          context.pop();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _Header(state: state),
              const Spacer(),
              artwork,
              const SizedBox(height: 32),
              _TrackInfo(state: state),
              const SizedBox(height: 20),
              _SeekBar(
                state: state,
                dragValue: _dragValue,
                onDragStart: (value) => setState(() => _dragValue = value),
                onDragEnd: (value) {
                  ref
                      .read(playerProvider.notifier)
                      .seekToFraction(value);
                  setState(() => _dragValue = null);
                },
              ),
              const SizedBox(height: 12),
              _MainControls(state: state, controller: controller),
              const SizedBox(height: 24),
              _SecondaryControls(state: state),
              const SizedBox(height: 16),
              _QualityBadge(state: state),
              const Spacer(),
            ],
          ),
        ),
      ),
    );

    // El desplazamiento del swipe también es un `Transform`: sólo se monta
    // mientras el dedo se mueve, para que en reposo la textura quede quieta.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _Background(state: state),
          if (_dragOffset == 0)
            body
          else
            Transform.translate(
              offset: Offset(0, _dragOffset.clamp(0, 400) * 0.35),
              child: body,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fondo
// ---------------------------------------------------------------------------

/// Fondo del player: el artwork desenfocado + gradiente oscuro.
///
/// El canvas animado va sólo en la portada (arriba), como en Apple Music: en
/// el fondo se ve el arte fijo para que los controles se sigan leyendo y no
/// haya dos vídeos corriendo a la vez.
class _Background extends StatelessWidget {
  const _Background({required this.state});

  final MetPlayerState state;

  @override
  Widget build(BuildContext context) {
    final artwork = state.artworkUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        if (artwork.isNotEmpty)
          Opacity(
            opacity: 0.30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: CachedNetworkImage(
                imageUrl: artwork,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC000000),
                Color(0x22000000),
                Color(0xE6000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.state});

  final MetPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Minimizar',
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.chevronDown, size: 26),
          ),
          Expanded(
            child: Column(
              children: [
                const Text('REPRODUCIENDO', style: AppTextStyles.overline),
                const SizedBox(height: 2),
                Text(
                  _sourceLabel(state),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cola',
            onPressed: () => QueueSheet.show(context),
            icon: const Icon(LucideIcons.listMusic, size: 22),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(MetPlayerState state) {
    final stream = state.stream;
    if (stream == null) return 'MetMusic';
    final provider = (stream.provider ?? '').toUpperCase();
    final quality = stream.qualityLabel;
    if (provider.isEmpty) return quality;
    return '$provider • $quality';
  }
}

// ---------------------------------------------------------------------------
// Info
// ---------------------------------------------------------------------------

class _TrackInfo extends ConsumerWidget {
  const _TrackInfo({required this.state});

  final MetPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.track;
    final isFavorite = ref.watch(currentTrackIsFavoriteProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (state.artist.isNotEmpty) state.artist,
                  if (state.album.isNotEmpty) state.album,
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        if (track != null)
          IconButton(
            tooltip: isFavorite ? 'Quitar de favoritos' : 'Favorito',
            onPressed: () => ref.read(playerProvider.notifier).toggleFavorite(),
            icon: Icon(
              isFavorite ? LucideIcons.heart : LucideIcons.heartOff,
              color: isFavorite ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seek bar
// ---------------------------------------------------------------------------

class _SeekBar extends StatelessWidget {
  const _SeekBar({
    required this.state,
    required this.dragValue,
    required this.onDragStart,
    required this.onDragEnd,
  });

  final MetPlayerState state;
  final double? dragValue;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final total = state.effectiveDuration;
    final value = dragValue ?? state.progress;
    final shownPosition = dragValue == null
        ? state.position
        : Duration(milliseconds: (total.inMilliseconds * dragValue!).round());

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChangeStart: onDragStart,
            onChanged: onDragStart,
            onChangeEnd: onDragEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DurationFormatter.format(shownPosition),
                  style: AppTextStyles.caption),
              Text(DurationFormatter.format(total),
                  style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Controles
// ---------------------------------------------------------------------------

class _MainControls extends StatelessWidget {
  const _MainControls({required this.state, required this.controller});

  final MetPlayerState state;
  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    final repeat = state.queue.repeat;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleIconButton(
          icon: LucideIcons.shuffle,
          active: state.queue.shuffle,
          tooltip: 'Aleatorio',
          onTap: controller.toggleShuffle,
        ),
        _CircleIconButton(
          icon: LucideIcons.skipBack,
          size: 30,
          tooltip: 'Anterior',
          onTap: controller.previous,
        ),
        _PlayPauseButton(
          playing: state.playing,
          loading: state.loading,
          onTap: controller.togglePlayPause,
        ),
        _CircleIconButton(
          icon: LucideIcons.skipForward,
          size: 30,
          tooltip: 'Siguiente',
          onTap: controller.next,
        ),
        _CircleIconButton(
          icon:
              repeat == LoopMode.one ? LucideIcons.repeat1 : LucideIcons.repeat,
          active: repeat != LoopMode.off,
          tooltip: repeat == LoopMode.one
              ? 'Repetir una'
              : repeat == LoopMode.all
                  ? 'Repetir todo'
                  : 'Repetir',
          onTap: controller.cycleRepeat,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.loading,
    required this.onTap,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.black,
                  ),
                )
              : Icon(
                  playing ? LucideIcons.pause : LucideIcons.play,
                  size: 30,
                  color: Colors.black,
                ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.size = 22,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: size,
          color: active ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

// ---------------------------------------------------------------------------
// Controles secundarios
// ---------------------------------------------------------------------------

class _SecondaryControls extends ConsumerWidget {
  const _SecondaryControls({required this.state});

  final MetPlayerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = state.track;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () {
            if (track != null) {
              AddToPlaylistSheet.show(context, track.trackId);
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          icon: const Icon(LucideIcons.plus, size: 16),
          label: const Text('Playlist'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => QueueSheet.show(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          icon: const Icon(LucideIcons.list, size: 16),
          label: const Text('Cola'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Badge de calidad
// ---------------------------------------------------------------------------

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.state});

  final MetPlayerState state;

  @override
  Widget build(BuildContext context) {
    final stream = state.stream;
    if (stream == null) return const SizedBox(height: 34);

    return GlassPlayerCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.signal, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            _label(stream.codec, stream.qualityLabel),
            style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
          ),
          if (stream.isPreview) ...[
            const SizedBox(width: 8),
            const Text('PREVIEW', style: AppTextStyles.caption),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String _label(String? codec, String qualityLabel) {
    final c = (codec ?? '').toUpperCase();
    if (c.isEmpty) return qualityLabel;
    return qualityLabel.toUpperCase().startsWith(c)
        ? qualityLabel
        : '$c $qualityLabel';
  }
}
