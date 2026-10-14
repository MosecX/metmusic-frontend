import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView que hostea el Web Component am-lyrics.
///
/// am-lyrics NO tiene loop de animación interno. Es un componente
/// "dumb": el consumidor debe empujar currentTime frame por frame
/// para que el karaoke avance. Este widget hace ese empuje con un
/// Ticker a ~33 Hz (delta mínimo de 30ms), lo bastante frecuente
/// para que la sincronía palabra-por-palabra se vea fluida sin
/// saturar el puente Dart-JS.
class AmLyricsWebView extends StatefulWidget {
  final String trackId;
  final String apiBase;
  final String apiToken;
  final String highlightColor;
  final Duration initialPosition;
  final ValueChanged<Duration>? onLineTap;
  final ValueChanged<String>? onError;

  const AmLyricsWebView({
    super.key,
    required this.trackId,
    required this.apiBase,
    required this.apiToken,
    this.highlightColor = '#BF5AF2',
    this.initialPosition = Duration.zero,
    this.onLineTap,
    this.onError,
  });

  @override
  State<AmLyricsWebView> createState() => AmLyricsWebViewState();
}

class AmLyricsWebViewState extends State<AmLyricsWebView>
    with SingleTickerProviderStateMixin {
  late final WebViewController _ctrl;
  late final Ticker _ticker;
  bool _ready = false;

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
              break;
            case 'error':
              final message = (data['message'] as String?) ?? 'unknown';
              widget.onError?.call(message);
              break;
          }
        },
      )
      ..loadFlutterAsset('assets/lyrics/index.html')
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _configure(),
      ));

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
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
    final trackId = jsonEncode(widget.trackId);
    final apiBase = jsonEncode(widget.apiBase);
    final apiToken = jsonEncode(widget.apiToken);
    final color = jsonEncode(widget.highlightColor);

    await _ctrl.runJavaScript('''
customElements.whenDefined('am-lyrics').then(() => {
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

  /// Llamar desde el widget padre cada vez que el player reporta
  /// nueva posición. Solo guarda; el Ticker decide cuándo cruzar
  /// el puente.
  void updatePosition(Duration position) {
    _pendingMs = position.inMilliseconds.toDouble();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _ctrl);
}
