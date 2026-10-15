import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView que hostea am-lyrics. El loop de sincronizacion vive DENTRO
/// del WebView (JS con requestAnimationFrame). Dart solo empuja updates
/// cada ~250ms via __setLyricsTime. Eso reduce el cruce del puente
/// Dart-JS de 20-33 Hz a 4 Hz, que es la diferencia entre lag y
/// fluidez en gama baja.
///
/// Tambien controla el visualizer Kawarp (canvas dentro del WebView,
/// estilo Monochrome): initVisualizer/setVisualizerEnabled/
/// setVisualizerCover. Las peticiones hechas antes de que la pagina
/// esté "ready" se encolan y se aplican al llegar el ready.
class AmLyricsWebView extends StatefulWidget {
  final String trackId;
  final String apiBase;
  final String apiToken;
  final String highlightColor;
  final Duration initialPosition;
  final bool noBlur;
  final ValueChanged<Duration>? onLineTap;
  final ValueChanged<String>? onError;
  final ValueChanged<String>? onDebug;

  const AmLyricsWebView({
    super.key,
    required this.trackId,
    required this.apiBase,
    required this.apiToken,
    this.highlightColor = '#BF5AF2',
    this.initialPosition = Duration.zero,
    this.noBlur = true,
    this.onLineTap,
    this.onError,
    this.onDebug,
  });

  @override
  State<AmLyricsWebView> createState() => AmLyricsWebViewState();
}

class AmLyricsWebViewState extends State<AmLyricsWebView> {
  late final WebViewController _ctrl;
  Timer? _pushTimer;
  bool _ready = false;
  bool _configured = false;
  Timer? _configureTimeout;

  double _pendingMs = 0;
  bool _pendingPlaying = false;

  // Estado del visualizer Kawarp: lo pedido vs. lo ya enviado al
  // WebView. "Requested" se guarda aunque la pagina no este lista;
  // "sent" evita reenviar el mismo estado en cada rebuild.
  String? _requestedCover;
  String? _sentCover;
  bool? _requestedVisualizer;
  bool? _sentVisualizer;

  /// Cada cuanto se empuja el tiempo al WebView. 250ms = 4 Hz.
  /// El loop rAF interno interpola entre pushes, asi que esto no
  /// afecta a la fluidez visual — solo al coste del puente.
  static const Duration _pushInterval = Duration(milliseconds: 250);

  /// CSS que Monochrome inyecta en el shadowRoot de am-lyrics
  /// (applyFullscreenLyricsShadowTweaks): transiciones de linea,
  /// opacidad del texto inactivo y scrollbar oculta.
  static const String _monochromeShadowCss = '''
.lyrics-line {
  transform-origin: left center;
  transition: opacity 0.42s ease, transform 0.55s cubic-bezier(0.22, 1, 0.36, 1) var(--lyrics-line-delay, 0ms), filter 0.48s cubic-bezier(0.22, 1, 0.36, 1) !important;
}
.lyrics-line:not(.active):not(.pre-active) {
  opacity: 0.44;
}
.lyrics-line-container {
  transition: transform 0.72s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.3s ease, color 0.3s ease !important;
}
.lyrics-line.active .lyrics-line-container,
.lyrics-line.pre-active .lyrics-line-container {
  transition: transform 0.56s cubic-bezier(0.22, 1, 0.36, 1), background-color 0.22s ease, color 0.22s ease !important;
}
.lyrics-line.active .lyrics-line-container {
  transform: scale(1.015);
}
.lyrics-container {
  scrollbar-width: none !important;
}
.lyrics-container::-webkit-scrollbar {
  width: 0 !important; height: 0 !important; display: none !important;
}
''';

  @override
  void initState() {
    super.initState();
    _pendingMs = widget.initialPosition.inMilliseconds.toDouble();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'AmLyricsBridge',
        onMessageReceived: (msg) {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          final type = data['type'] as String?;
          switch (type) {
            case 'line-click':
              final ts = (data['timestamp'] as num).toInt();
              widget.onLineTap?.call(Duration(milliseconds: ts));
              break;
            case 'ready':
              _ready = true;
              _configureTimeout?.cancel();
              widget.onDebug?.call('am-lyrics ready');
              _startPushTimer();
              _pushTime();
              // Visualizer: init primero (crea+arranca Kawarp) y luego
              // aplicar el estado encolado (en modo normal lo para y
              // oculta el canvas al instante). Cover y estilo Monochrome
              // tambien se encolan hasta aqui.
              unawaited(initVisualizer());
              unawaited(_applyVisualizerEnabled());
              unawaited(_flushCover());
              unawaited(_injectStyle(_monochromeShadowCss));
              break;
            case 'error':
              final message = (data['message'] as String?) ?? 'unknown';
              widget.onError?.call(message);
              break;
            case 'debug':
              widget.onDebug?.call(
                (data['message'] as String?) ?? 'debug',
              );
              break;
          }
        },
      )
      ..loadFlutterAsset('assets/lyrics/index.html')
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          widget.onDebug?.call('onPageFinished fired');
          _configure();
        },
        onWebResourceError: (error) {
          widget.onError?.call(
            'webresource: ${error.errorCode} ${error.description}',
          );
        },
      ));
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    _configureTimeout?.cancel();
    super.dispose();
  }

  void _startPushTimer() {
    _pushTimer?.cancel();
    _pushTimer = Timer.periodic(_pushInterval, (_) => _pushTime());
  }

  Future<void> _pushTime() async {
    if (!_ready) return;
    final ms = _pendingMs;
    final playing = _pendingPlaying ? 'true' : 'false';
    await _ctrl.runJavaScript(
      'window.__setLyricsTime && window.__setLyricsTime($ms, $playing);',
    );
  }

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;

    final trackId = jsonEncode(widget.trackId);
    final apiBase = jsonEncode(widget.apiBase);
    final apiToken = jsonEncode(widget.apiToken);
    final color = jsonEncode(widget.highlightColor);
    final noBlur = widget.noBlur ? 'true' : 'false';

    _configureTimeout = Timer(const Duration(seconds: 5), () {
      if (!_ready) {
        widget.onError?.call(
          'timeout: am-lyrics no se registro en 5s. '
          'Revisar carga de am-lyrics.iife.js en el WebView.',
        );
      }
    });

    await _ctrl.runJavaScript('''
      customElements.whenDefined('am-lyrics').then(() => {
        const report = (type, message) => {
          AmLyricsBridge.postMessage(JSON.stringify({
            type: type, message: message
          }));
        };
        report('debug', 'am-lyrics custom element defined');
        const el = document.querySelector('am-lyrics');
        if (!el) {
          AmLyricsBridge.postMessage(JSON.stringify({
            type: 'error',
            message: 'am-lyrics element not in DOM'
          }));
          return;
        }
        el.setAttribute('track-id', $trackId);
        el.setAttribute('api-base', $apiBase);
        el.setAttribute('api-token', $apiToken);
        el.setAttribute('highlight-color', $color);
        el.setAttribute('autoscroll', '');
        el.setAttribute('interpolate', '');
        if ($noBlur) {
          el.setAttribute('no-blur', '');
        } else {
          // Toggle real: el HTML lo trae por defecto, asi que para
          // poder volver a blur hay que quitar el atributo.
          el.removeAttribute('no-blur');
        }
        el.addEventListener('line-click', (e) => {
          AmLyricsBridge.postMessage(JSON.stringify({
            type: 'line-click',
            timestamp: e.detail.timestamp
          }));
        });
        window.__amLyrics = el;
        AmLyricsBridge.postMessage(JSON.stringify({ type: 'ready' }));
      }).catch((err) => {
        AmLyricsBridge.postMessage(JSON.stringify({
          type: 'error',
          message: 'whenDefined failed: ' + String(err)
        }));
      });
    ''');
  }

  /// Inyecta CSS en el shadowRoot de am-lyrics (patron Monochrome).
  Future<void> _injectStyle(String css) async {
    final jsonCss = jsonEncode(css);
    await _ctrl.runJavaScript(
      'window.__injectLyricsStyle && window.__injectLyricsStyle($jsonCss);',
    );
  }

  /// El widget padre llama esto cada vez que el player reporta
  /// nueva posicion. Solo guarda; el Timer empuja cada 250ms.
  void updatePosition(Duration position) {
    _pendingMs = position.inMilliseconds.toDouble();
  }

  /// El widget padre llama esto cuando cambia el estado de play/pause.
  void updatePlaying(bool playing) {
    _pendingPlaying = playing;
    // Empujar inmediatamente para arrancar/parar el rAF sin esperar
    // al siguiente tick del Timer.
    unawaited(_pushTime());
  }

  /// URL del artwork para el visualizer Kawarp. Se encola hasta que
  /// la pagina este lista y se deduplica para no reenviar la misma.
  Future<void> setVisualizerCover(String coverUrl) async {
    if (coverUrl == _requestedCover) return;
    _requestedCover = coverUrl;
    await _flushCover();
  }

  Future<void> _flushCover() async {
    final url = _requestedCover;
    if (!_ready || url == null || url == _sentCover) return;
    _sentCover = url;
    await _ctrl.runJavaScript(
      'window.__setVisualizerCover && '
      'window.__setVisualizerCover(${jsonEncode(url)});',
    );
  }

  /// Activa/desactiva el canvas Kawarp (solo en modo visualizer).
  /// Se encola hasta ready y se deduplica.
  Future<void> setVisualizerEnabled(bool enabled) async {
    if (enabled == _requestedVisualizer) return;
    _requestedVisualizer = enabled;
    await _applyVisualizerEnabled();
  }

  Future<void> _applyVisualizerEnabled() async {
    final enabled = _requestedVisualizer;
    if (!_ready || enabled == null || enabled == _sentVisualizer) return;
    _sentVisualizer = enabled;
    await _ctrl.runJavaScript(
      'window.__setVisualizerEnabled && '
      'window.__setVisualizerEnabled($enabled);',
    );
  }

  /// Inicializa el visualizer Kawarp dentro del WebView. Se llama
  /// cuando el bridge reporta 'ready'.
  Future<void> initVisualizer() async {
    await _ctrl.runJavaScript(
      'window.__initVisualizer && window.__initVisualizer();',
    );
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(
        controller: _ctrl,
        // Sin esto, el VerticalDragGestureRecognizer del modal bottom sheet
        // gana la arena de gestos y el WebView nunca recibe los touchmove:
        // el scroll manual de las letras no funcionaria. Eager hace que el
        // WebView reclame los gestos que empiezan dentro de su area (para
        // cerrar la hoja, arrastrar desde el header).
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
        },
      );
}
