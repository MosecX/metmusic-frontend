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
import 'lyrics_sheet.dart';
import 'player_artwork.dart';
import 'queue_sheet.dart';

/// Reproductor a pantalla completa (estilo Glass 1).
class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  /// El vídeo reportó su aspecto nativo: la caja se ajusta al tamaño real
  /// del canvas (con animación corta, para que no salte).
  void _onCanvasAspect(double aspect) {
    if (_canvasAspect != null && (_canvasAspect! - aspect).abs() < 0.001) {
      return;
    }
    setState(() => _canvasAspect = aspect);
  }

  /// Valor del slider mientras el usuario arrastra.
  double? _dragValue;

  /// Desplazamiento vertical para el swipe-down.
  double _dragOffset = 0;

  /// Relación de aspecto nativa del canvas actual (ancho / alto). `null`
  /// mientras el vídeo no inicializa: la caja usa la estimación clásica de
  /// 1.48× ancho hasta que el propio vídeo reporta su tamaño real.
  double? _canvasAspect;

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
      if (_dragValue != null || _canvasAspect != null) {
        setState(() {
          _dragValue = null;
          _canvasAspect = null;
        });
      }
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

    // Info + controles: comunes a los dos modos (con y sin canvas).
    final below = <Widget>[
      _TrackInfo(state: state),
      const SizedBox(height: 20),
      _SeekBar(
        state: state,
        dragValue: _dragValue,
        onDragStart: (value) => setState(() => _dragValue = value),
        onDragEnd: (value) {
          ref.read(playerProvider.notifier).seekToFraction(value);
          setState(() => _dragValue = null);
        },
      ),
      const SizedBox(height: 12),
      _MainControls(state: state, controller: controller),
      const SizedBox(height: 24),
      _SecondaryControls(state: state),
      const SizedBox(height: 16),
      _QualityBadge(state: state),
    ];

    // Si la canción tiene canvas animado, el canvas REEMPLAZA a la portada en
    // modo "portada expandida" (estilo Apple Music / player de referencia):
    // el vídeo ocupa toda la zona alta —también por detrás de la info— y se
    // disuelve en el player en vez de cortarse en un recuadro. Los canvas
    // verticales (1080×1920) entran casi completos. Si no tiene canvas, el
    // player queda exactamente como antes: sólo la portada flotante con su
    // encogido al pausar.
    //
    // La portada queda de base debajo del vídeo, por si tarda en cargar o si
    // el códec falla. Con canvas no se aplica ningún `Transform`/escala sobre
    // la `Texture`: es lo que deforma los cuadros en diagonal.
    final List<Widget> columnChildren;
    if (hasCanvas) {
      columnChildren = [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _Header(state: state),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // La caja sigue el aspecto NATIVO del vídeo (9:16, 1:1…):
              // así ningún canvas se recorta ni se estira, se muestra
              // entero a ancho completo. Hasta que el vídeo inicializa se
              // estima 1.48× ancho (típico canvas vertical) para no saltar
              // al abrir el player.
              final aspect = _canvasAspect;
              final naturalHeight =
                  (aspect != null && aspect.isFinite && aspect > 0)
                      ? constraints.maxWidth / aspect
                      : constraints.maxWidth * 1.48;
              final videoHeight =
                  naturalHeight.clamp(0.0, constraints.maxHeight).toDouble();

              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    left: 0,
                    right: 0,
                    height: videoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: PlayerArtwork(
                            url: state.artworkUrl,
                            size: constraints.maxWidth,
                            radius: 0,
                            heroTag: AppConstants.heroArtworkTag,
                            elevated: false,
                          ),
                        ),
                        CanvasOverlay(
                          media: canvasMedia,
                          playing: state.playing,
                          radius: 0,
                          onAspectChanged: _onCanvasAspect,
                        ),
                        // El vídeo se funde con el player: arriba y a los
                        // lados este feather, abajo el velo de la info.
                        const _CanvasFeather(),
                      ],
                    ),
                  ),
                  // La info se superpone sobre la cola del vídeo: 72 px de
                  // fundido transparente→fondo y el resto sobre un velo casi
                  // opaco, así el texto se lee siempre y el vídeo se sigue
                  // insinuando por detrás en lugar de terminar en seco.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xD70A0A0F),
                            Color(0xE60A0A0F),
                          ],
                          stops: [0.0, 0.17, 1.0],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 72, 20, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: below,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ];
    } else {
      // Sin canvas: sólo la portada. No se envuelve en un ClipRRect porque
      // PlayerArtwork dibuja su propia sombra hacia afuera y un clip la
      // cortaría.
      Widget artwork = PlayerArtwork(
        url: state.artworkUrl,
        size: artworkSize,
        radius: 18,
        heroTag: AppConstants.heroArtworkTag,
        elevated: true,
      );
      artwork = AnimatedScale(
        scale: state.playing ? 1 : 0.9,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: artwork,
      );

      columnChildren = [
        _Header(state: state),
        const Spacer(),
        artwork,
        const SizedBox(height: 32),
        ...below,
        const Spacer(),
      ];
    }

    final body = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dy);
      },
      onVerticalDragEnd: (details) {
        // Un sólo deslizamiento cierra el player: por la distancia
        // recorrida o por la velocidad, porque un gesto rápido no siempre
        // llega a los 90 px antes de soltar.
        final flick =
            _dragOffset > 12 && details.velocity.pixelsPerSecond.dy > 700;
        if (_dragOffset > 90 || flick) {
          context.pop();
        } else {
          setState(() => _dragOffset = 0);
        }
      },
      onVerticalDragCancel: () {
        if (_dragOffset != 0) setState(() => _dragOffset = 0);
      },
      child: SafeArea(
        child: hasCanvas
            ? Column(children: columnChildren)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: columnChildren),
              ),
      ),
    );

    // El `Transform.translate` del swipe va SIEMPRE montado. Con offset
    // cero la matriz es identidad y Flutter pinta al hijo en su sitio sin
    // capa ni matriz sobre la textura; además, montarlo/desmontarlo a mitad
    // de gesto destruía el detector y obligaba a deslizar dos veces para
    // cerrar. Una traslación pura tampoco remuestrea la `Texture`: sólo la
    // desplaza mientras el dedo se mueve.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _Background(state: state),
          Transform.translate(
            offset: Offset(0, _dragOffset.clamp(0.0, 400.0) * 0.35),
            child: body,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fundido del canvas
// ---------------------------------------------------------------------------

/// Suaviza los bordes del canvas para que el vídeo se funda con el fondo
/// del player en lugar de cortarse en seco: arriba y abajo con un blur
/// degradado (bandas de `BackdropFilter` + velo del color de fondo) y a
/// los lados con una viñeta. El velo de la info, que va justo encima,
/// remata el borde inferior.
///
/// Todo se pinta POR ENCIMA de la textura como un hermano del Stack,
/// nunca la envuelve: un `Opacity`, `ShaderMask` o `FittedBox` alrededor
/// de una `Texture` crea una capa con matriz y es lo que deforma los
/// cuadros en diagonal en Android. Ni los gradientes ni los
/// `BackdropFilter` transforman la textura: sólo leen el resultado ya
/// compuesto en pantalla.
class _CanvasFeather extends StatelessWidget {
  const _CanvasFeather();

  @override
  Widget build(BuildContext context) {
    const fade = AppColors.background;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        if (!height.isFinite || height <= 0) return const SizedBox.shrink();

        // Bandas de desenfoque: crecen hacia el borde y el velo de la
        // parte exterior las disuelve en el fondo del player.
        final topBand = (height * 0.16).clamp(72.0, 150.0);
        final bottomBand = (height * 0.20).clamp(88.0, 190.0);

        // Velo que tinta las bandas y tapa la costura entre el vídeo
        // desenfocado y el nítido: opaco en el borde y transparente ya
        // pasada la banda.
        final topVeil = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fade, fade.withValues(alpha: 0.45), Colors.transparent],
          stops: const [0.0, 0.18, 0.34],
        );
        final bottomVeil = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [fade, fade.withValues(alpha: 0.45), Colors.transparent],
          stops: const [0.0, 0.20, 0.36],
        );
        // Los laterales hacen de viñeta suave hacia los bordes de la
        // pantalla.
        const horizontal = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [fade, Colors.transparent, Colors.transparent, fade],
          stops: [0.0, 0.09, 0.91, 1.0],
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topBand,
              child: const _BlurBand(alignment: Alignment.topCenter),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomBand,
              child: const _BlurBand(alignment: Alignment.bottomCenter),
            ),
            DecoratedBox(
              decoration: BoxDecoration(gradient: topVeil),
            ),
            DecoratedBox(
              decoration: BoxDecoration(gradient: bottomVeil),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: horizontal),
            ),
          ],
        );
      },
    );
  }
}

/// Banda de desenfoque progresivo sobre un borde del canvas: el blur va
/// de 0 % (hacia el centro del vídeo) al 100 % (pegado al borde) en un
/// degradado continuo.
///
/// Un único `BackdropFilter` se enmascara con un `ShaderMask` cuyo alpha
/// cae linealmente desde el borde: donde el shader es transparente se ve
/// el vídeo nítido y donde es opaco está totalmente desenfocado, con todo
/// el rango intermedio en entre. El velo del [_CanvasFeather] se pinta
/// encima y remata la disolución hacia el fondo.
///
/// Ni la máscara ni el filtro envuelven la textura en una capa con
/// matriz: sólo leen el resultado ya compuesto en pantalla.
class _BlurBand extends StatelessWidget {
  const _BlurBand({required this.alignment});

  /// Borde de la banda pegado al fondo del player (top o bottom).
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    // Degradado del DESENFOQUE: opaco (100 % de blur) pegado al borde del
    // canvas y transparente (0 %, vídeo nítido) hacia el centro, con todo
    // el rango intermedio en entre — no un recuadro con cortes duros.
    final gradient = LinearGradient(
      begin: alignment,
      end: Alignment(-alignment.x, -alignment.y),
      colors: const [
        Colors.white,
        Color(0xB3FFFFFF), // 70 %
        Color(0x4DFFFFFF), // 30 %
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: gradient.createShader,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: const SizedBox.expand(),
        ),
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
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => LyricsSheet.show(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          icon: const Icon(LucideIcons.captions, size: 16),
          label: const Text('Letras'),
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
