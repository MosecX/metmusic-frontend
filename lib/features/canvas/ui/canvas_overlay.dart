import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/canvas.dart';
import '../../../core/theme/app_colors.dart';

/// Reproduce el canvas (vídeo animado de portada) de un track.
///
/// El vídeo hace loop mientras la canción suena y se congela al pausar, así
/// el visualizador sigue mandando el ritmo del player.
///
/// El canvas **es** la portada: ocupa exactamente la caja del artwork, se
/// recorta al estilo `BoxFit.cover` y mantiene el borde/redondeado del
/// reproductor para que siga leyéndose como un player y no como un vídeo
/// suelto.
///
/// - `kind: mp4` → vídeo progresivo.
/// - `kind: hls` → playlist HLS (formatHint).
///
/// Si el backend responde 404 no se monta el widget, y si el códec falla en
/// el dispositivo se oculta y queda el artwork estático de abajo.
class CanvasOverlay extends StatefulWidget {
  const CanvasOverlay({
    super.key,
    required this.media,
    required this.playing,
    this.fit = BoxFit.cover,
    this.radius = 18,
  });

  /// Canvas ya resuelto por `canvasProvider` (nunca null).
  final CanvasMedia media;

  /// Sigue el estado del audio: el visualizador se congela al pausar.
  final bool playing;

  final BoxFit fit;

  /// Mismo radio que el artwork para que la portada no cambie de forma.
  final double radius;

  /// Tamaño al que hay que dibujar el vídeo para emular [BoxFit] sin escala
  /// ni transformación.
  ///
  /// `cover` llena la caja y corta lo que sobra; `contain` entra entero y
  /// deja el resto al artwork de abajo.
  @visibleForTesting
  static Size fittedSize(Size box, double aspect, BoxFit fit) {
    if (box.isEmpty || !aspect.isFinite || aspect <= 0) return Size.zero;
    if (fit == BoxFit.fill) return box;

    final boxAspect = box.width / box.height;
    // Píxeles enteros: una caja fraccionada muestrea la textura fuera de
    // grilla y se ve borrosa/temblorosa en algunos dispositivos.
    Size rounded(double width, double height) => Size(
          width.roundToDouble().clamp(1.0, double.infinity).toDouble(),
          height.roundToDouble().clamp(1.0, double.infinity).toDouble(),
        );

    switch (fit) {
      case BoxFit.contain:
        // Encaja entero: manda el lado que menos hay que escalar.
        return boxAspect > aspect
            ? rounded(box.height * aspect, box.height)
            : rounded(box.width, box.width / aspect);
      case BoxFit.cover:
      default:
        // Llena todo: manda el lado que hay que escalar más y el resto corta.
        return boxAspect > aspect
            ? rounded(box.width, box.width / aspect)
            : rounded(box.height * aspect, box.height);
    }
  }

  @override
  State<CanvasOverlay> createState() => _CanvasOverlayState();
}

class _CanvasOverlayState extends State<CanvasOverlay> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CanvasOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.url != widget.media.url) {
      _disposeController();
      _load();
      return;
    }
    if (oldWidget.playing != widget.playing) _syncPlayback();
  }

  Future<void> _load() async {
    final media = widget.media;
    if (media.url.isEmpty) return;
    VideoPlayerController? pending;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(media.url),
        formatHint: media.isHls ? VideoFormat.hls : null,
      );
      pending = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      controller.addListener(_onControllerUpdate);
      if (widget.playing) {
        await controller.play();
      } else {
        await controller.pause();
      }

      if (!mounted) {
        pending = null;
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
      pending = null;
    } catch (_) {
      // Códec no soportado, red o 404 tardío: se queda el artwork estático.
      await pending?.dispose();
      if (mounted) setState(() => _ready = false);
    }
  }

  /// Un error del reproductor (códec raro, stream cortado) no debe dejar un
  /// frame congelado o verde encima de la portada: se rinde y se ve el arte.
  void _onControllerUpdate() {
    final controller = _controller;
    if (controller == null || !_ready) return;
    if (controller.value.hasError) {
      setState(() => _ready = false);
    }
  }

  Future<void> _syncPlayback() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (widget.playing) {
        await controller.play();
      } else {
        await controller.pause();
      }
    } catch (_) {
      // El controller se pudo haber disposed entre frames.
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _ready = false;
    controller?.removeListener(_onControllerUpdate);
    controller?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) return const SizedBox.shrink();

    // `VideoPlayer` dibuja una `Texture`. Envolverla en un `FittedBox`, un
    // `Opacity` o cualquier `Transform`/escala obliga al compositor a
    // remuestrear la textura con una matriz que no es la de su caja y en
    // Android eso se ve como píxeles estirados en diagonal. Por eso el
    // tamaño se calcula a mano, alineado a la grilla de píxeles real del
    // dispositivo, y la textura se dibuja en su caja final, sin capas ni
    // transformaciones encima.
    final Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final aspect = controller.value.aspectRatio <= 0
              ? 1.0
              : controller.value.aspectRatio;
          final dpr = MediaQuery.devicePixelRatioOf(context);
          Size snap(Size value) => Size(
                (value.width * dpr).round() / dpr,
                (value.height * dpr).round() / dpr,
              );
          final size = snap(
            CanvasOverlay.fittedSize(
              Size(constraints.maxWidth, constraints.maxHeight),
              aspect,
              widget.fit,
            ),
          );
          if (size.isEmpty) return const SizedBox.shrink();
          return Align(
            alignment: Alignment.center,
            child: SizedBox.fromSize(
              size: size,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
    );

    // A sangre (radio 0) no se dibuja el borde: quedaría una línea sobre
    // los bordes de la pantalla.
    if (widget.radius <= 0) return content;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: content,
    );
  }
}
