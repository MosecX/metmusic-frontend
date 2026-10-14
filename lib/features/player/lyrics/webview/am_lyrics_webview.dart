import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView que hostea el Web Component am-lyrics.
///
/// am-lyrics NO tiene loop de animación interno. El consumidor
/// debe empujar currentTime frame por frame. Este widget hace ese
/// empuje con un Ticker a ~33 Hz (delta mínimo de 30ms).
class AmLyricsWebView extends StatefulWidget {
  final String trackId;
  final String apiBase;
  final String apiToken;
  final String highlightColor;
  final Duration initialPosition;
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
    this.onLineTap,
    this.onError,
    this.onDebug,
  });

  @override
  State<AmLyricsWebView> createState() => AmLyricsWebViewState();
}

class AmLyricsWebViewState extends State<AmLyricsWebView>
    with SingleTickerProviderStateMixin {
  late final WebViewController _ctrl;
  late final Ticker _ticker;
  bool _ready = false;
  bool _configured = false;
  Timer? _configureTimeout;

  double _pendingMs = 0;
  double _lastSentMs = -1;

  static const double _minDeltaMs = 30.0;

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

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _configureTimeout?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration _) {
    if (!_ready) return;
    if ((_pendingMs - _lastSentMs).abs() < _minDeltaMs) return;
    _lastSentMs = _pendingMs;
    _ctrl.runJavaScript(
      'window.__amLyrics && (window.__amLyrics.currentTime = $_pendingMs);',
    );
  }

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;

    final trackId = jsonEncode(widget.trackId);
    final apiBase = jsonEncode(widget.apiBase);
    final apiToken = jsonEncode(widget.apiToken);
    final color = jsonEncode(widget.highlightColor);

    _configureTimeout = Timer(const Duration(seconds: 5), () {
      if (!_ready) {
        widget.onError?.call(
          'timeout: am-lyrics no se registró en 5s. '
          'Revisar import de am-lyrics.min.js en el WebView.',
        );
      }
    });

    await _ctrl.runJavaScript('''
      (function() {
        const report = (type, message) => {
          AmLyricsBridge.postMessage(JSON.stringify({
            type: type, message: message
          }));
        };
        report('debug', 'configure start, readyState=' +
                document.readyState);
        const el = document.querySelector('am-lyrics');
        if (!el) {
          report('error', 'am-lyrics no está en el DOM');
          return;
        }
        report('debug', 'am-lyrics element found');
        customElements.whenDefined('am-lyrics')
          .then(() => {
            report('debug', 'am-lyrics custom element defined');
            el.setAttribute('track-id', $trackId);
            el.setAttribute('api-base', $apiBase);
            el.setAttribute('api-token', $apiToken);
            el.setAttribute('highlight-color', $color);
            el.setAttribute('autoscroll', '');
            el.setAttribute('interpolate', '');
            el.addEventListener('line-click', (e) => {
              AmLyricsBridge.postMessage(JSON.stringify({
                type: 'line-click',
                timestamp: e.detail.timestamp
              }));
            });
            window.__amLyrics = el;
            report('ready', 'configured');
          })
          .catch((err) => {
            report('error', 'whenDefined failed: ' + String(err));
          });
      })();
    ''');
  }

  /// El widget padre llama esto cada vez que el player reporta
  /// nueva posición. Solo guarda; el Ticker decide cuándo cruzar
  /// el puente.
  void updatePosition(Duration position) {
    _pendingMs = position.inMilliseconds.toDouble();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _ctrl);
}
