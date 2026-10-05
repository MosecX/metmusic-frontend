import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../services/service_providers.dart';

/// Reproduce el canvas (vídeo animado de portada) de un track en loop.
///
/// - `kind: mp4` → vídeo progresivo.
/// - `kind: hls` → playlist HLS (formatHint).
///
/// Si el backend responde 404, no se renderiza nada y el player muestra el
/// artwork estático.
class CanvasOverlay extends ConsumerStatefulWidget {
  const CanvasOverlay({
    super.key,
    required this.trackId,
    this.fit = BoxFit.cover,
    this.opacity = 1.0,
  });

  final String trackId;
  final BoxFit fit;
  final double opacity;

  @override
  ConsumerState<CanvasOverlay> createState() => _CanvasOverlayState();
}

class _CanvasOverlayState extends ConsumerState<CanvasOverlay> {
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
    if (oldWidget.trackId != widget.trackId) {
      _disposeController();
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.trackId.isEmpty) return;
    try {
      final media =
          await ref.read(canvasServiceProvider).getCanvas(widget.trackId);
      if (media == null || media.url.isEmpty || !mounted) return;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(media.url),
        formatHint: media.isHls ? VideoFormat.hls : null,
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.play();
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      // Sin canvas (404, error de red o códec no soportado): artwork estático.
      if (mounted) setState(() => _ready = false);
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _ready = false;
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

    final aspect = controller.value.aspectRatio <= 0
        ? 1.0
        : controller.value.aspectRatio;

    return Opacity(
      opacity: widget.opacity,
      child: FadeTransition(
        opacity: const AlwaysStoppedAnimation(1.0),
        child: SizedBox.expand(
          child: FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: aspect * 1000,
              height: 1000,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}
