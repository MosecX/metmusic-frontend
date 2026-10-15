import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView que hostea am-lyrics. A diferencia del diseño anterior,
/// el loop de sincronización vive DENTRO del WebView (JS con
/// requestAnimationFrame). Dart solo empuja updates cada ~250ms
/// vía __setLyricsTime. Eso reduce el cruce del puente Dart-JS de
/// 20-33 Hz a 4 Hz, que es la diferencia entre lag y fluidez en
/// gama baja.
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
    this.noBlur = false,
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

  /// Cada cuánto se empuja el tiempo al WebView. 250ms = 4 Hz.
  /// El loop rAF interno interpola entre pushes, así que esto no
  /// afecta a la fluidez visual — solo al coste del puente.
  static const Duration _pushInterval = Duration(milliseconds: 250);

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
          'timeout: am-lyrics no se registró en 5s. '
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
          // Toggle real: el HTML lo trae por defecto, así que para
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

  /// El widget padre llama esto cada vez que el player reporta
  /// nueva posición. Solo guarda; el Timer empuja cada 250ms.
  void updatePosition(Duration position) {
    _pendingMs = position.inMilliseconds.toDouble();
  }

  /// El widget padre llama esto cuando cambia el estado de play/pause.
  void updatePlaying(bool playing) {
    _pendingPlaying = playing;
    // Empujar inmediatamente para arrancar/parar el rAF sin esperar
    // al siguiente tick del Timer.
    _pushTime();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _ctrl);
}
