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

  /// Cada cuanto se empuja el tiempo al WebView. 250ms = 4 Hz.
  /// El loop rAF interno interpola entre pushes, asi que esto no
  /// afecta a la fluidez visual — solo al coste del puente.
  static const Duration _pushInterval = Duration(milliseconds: 250);

  /// CSS inyectado en el shadowRoot de am-lyrics — "blur con coste
  /// controlado" (Apple Music look): tipografia SF, escalera de
  /// opacidades 1 / 0.62 / 0.45, glow blanco en la activa, contain por
  /// linea, blur SOLO en la linea pre-active y will-change acotado a la
  /// activa. En gama baja (`data-tier="low"`, lo pone index.html) el
  /// blur de la pre-active se apaga: la GPU chica lo paga caro y la
  /// escalera de opacidades ya alcanza.
  ///
  /// Notas de especificidad (gamma): con `no-blur` puesto el componente
  /// aplica `:host([no-blur]) .lyrics-line` (0,3,0 con !important):
  /// filter:none y transition-property opacity+transform. La transicion
  /// base ya usa esa misma lista (sin filter), asi que no hay choque.
  /// El blur de pre-active SI necesita ganarle: lleva el prefijo
  /// `.lyrics-container ` (0,4,0), igual que el transform del
  /// contenedor activo, que desempata contra el `scale(1)` del
  /// componente (misma especificidad 0,3,0, orden de hojas incierto).
  /// El apagado por gama baja suma `:host([data-tier="low"])` (0,5,0):
  /// le gana a la regla del blur, ambas con !important.
  static const String _monochromeShadowCss = '''
/* Tipografía Apple Music. */
.lyrics-line,
.lyrics-line-container,
.lyrics-line span,
.lyrics-line-container span,
[class="lyric"] {
  font-weight: 700 !important;
  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Inter', 'Helvetica Neue', system-ui, sans-serif !important;
  letter-spacing: -0.025em !important;
  line-height: 1.2 !important;
}

/* Contain por línea, versión conservadora: solo layout y paint.
   NO contain: style (contaminaría la herencia de variables CSS) ni
   contain: size (colapsa las líneas a 0px). Tampoco
   content-visibility: dibujaba cajas grises con el intrinsic-size. */
.lyrics-line {
  contain: layout paint;
  transform-origin: left center;
  transition:
    opacity 0.32s ease,
    transform 0.4s cubic-bezier(0.22, 1, 0.36, 1) !important;
}

/* Líneas inactivas lejanas: solo opacidad (45 %, escalera Apple Music),
   sin filter, sin content-visibility, sin contain-intrinsic-size. Las
   gaps inactivas no importan: el componente las colapsa a height:0. */
.lyrics-line:not(.active):not(.pre-active) {
  opacity: 0.45 !important;
}

/* Línea siguiente (pre-active): blur suave, opacidad intermedia.
   Prefijo .lyrics-container para ganarle a :host([no-blur]) (0,3,0). */
.lyrics-container .lyrics-line.pre-active {
  opacity: 0.62 !important;
  filter: blur(0.04em) !important;
}

/* Gama baja: la GPU chica paga caro el blur de la pre-active; la
   escalera de opacidades ya alcanza. :host([data-tier]) (0,5,0) le gana
   a la regla de arriba (0,4,0), ambas con !important. */
:host([data-tier="low"]) .lyrics-container .lyrics-line.pre-active {
  filter: none !important;
}

/* Línea activa: sin blur, opacidad completa y glow blanco suave
   (text-shadow, no filter: el filter crearia una capa GPU). */
.lyrics-line.active {
  opacity: 1 !important;
  filter: none !important;
  text-shadow: 0 0 18px rgba(255, 255, 255, 0.22) !important;
}

/* will-change SOLO en la línea activa. Sin will-change: filter:
   crear y destruir capas GPU por cada cambio de línea es más caro
   que el blur mismo. */
.lyrics-line.active {
  will-change: transform, opacity;
}

/* Animación de entrada: solo transform. */
.lyrics-container .lyrics-line.active .lyrics-line-container {
  transform: scale(1.02);
  transition: transform 0.4s cubic-bezier(0.22, 1, 0.36, 1) !important;
}

/* Scroll sin barra. */
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
        // interpolate lo decide index.html (logica isLowEnd): no se
        // toca aqui, si no se re-encenderia en gama baja.
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
