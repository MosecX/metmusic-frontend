import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hoja de letras am-lyrics embebida como WebView.
///
/// El Web Component recibe `track-id` / `api-base` / `api-token` y pide sus
/// propias letras al backend; Flutter sólo empuja el tiempo de reproducción,
/// el play/pause y convierte los `line-click` en seek.
class AmLyricsWebView extends StatefulWidget {
  const AmLyricsWebView({
    super.key,
    required this.trackId,
    required this.apiBase,
    required this.apiToken,
    this.highlightColor = '#BF5AF2',
    this.initialPosition = Duration.zero,
    this.onLineTap,
  });

  final String trackId;
  final String apiBase;
  final String apiToken;
  final String highlightColor;

  /// Posición que se aplica al terminar de cargar la página.
  final Duration initialPosition;

  final ValueChanged<Duration>? onLineTap;

  @override
  State<AmLyricsWebView> createState() => AmLyricsWebViewState();
}

class AmLyricsWebViewState extends State<AmLyricsWebView> {
  late final WebViewController _ctrl;
  bool _ready = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'AmLyricsBridge',
        onMessageReceived: (msg) {
          final data = jsonDecode(msg.message) as Map<String, dynamic>;
          if (data['type'] == 'line-click') {
            widget.onLineTap?.call(
              Duration(milliseconds: (data['timestamp'] as num).toInt()),
            );
          }
        },
      )
      ..loadFlutterAsset('assets/lyrics/index.html')
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _configure()),
      );
  }

  @override
  void didUpdateWidget(covariant AmLyricsWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final credentialsChanged = oldWidget.trackId != widget.trackId ||
        oldWidget.apiBase != widget.apiBase ||
        oldWidget.apiToken != widget.apiToken;
    if (!credentialsChanged) return;
    // Pista nueva: vuelve a correr el provider con los nuevos atributos.
    _paused = false;
    if (_ready) {
      _apply();
    }
  }

  String _configureJs() {
    final trackId = jsonEncode(widget.trackId);
    final apiBase = jsonEncode(widget.apiBase);
    final apiToken = jsonEncode(widget.apiToken);
    final color = jsonEncode(widget.highlightColor);
    final position = widget.initialPosition.inMilliseconds;
    // IIFE + guard: repetir la configuración no duplica el listener.
    return '''
      (() => {
        const el = document.querySelector('am-lyrics');
        if (!el) return;
        el.setAttribute('track-id', $trackId);
        el.setAttribute('api-base', $apiBase);
        el.setAttribute('api-token', $apiToken);
        el.setAttribute('highlight-color', $color);
        el.currentTime = $position;
        if (!el.__amLyricsBridgeBound) {
          el.__amLyricsBridgeBound = true;
          el.addEventListener('line-click', (e) => {
            AmLyricsBridge.postMessage(JSON.stringify({
              type: 'line-click',
              timestamp: e.detail.timestamp
            }));
          });
        }
        window.__amLyrics = el;
      })();
    ''';
  }

  Future<void> _apply() => _ctrl.runJavaScript(_configureJs());

  Future<void> _configure() async {
    await _apply();
    if (mounted) _ready = true;
  }

  Future<void> _js(String code) async {
    if (!_ready) return;
    await _ctrl.runJavaScript(code);
  }

  /// Empuja la posición real del reproductor al componente.
  Future<void> updatePosition(Duration position) {
    if (_paused) return Future<void>.value();
    return _js(
      'window.__amLyrics.currentTime = ${position.inMilliseconds};',
    );
  }

  /// Reanuda desde [startMs] (los ticks de posición vuelven a empujarse).
  Future<void> play(double startMs) {
    _paused = false;
    return _js('window.__amLyrics.currentTime = $startMs;');
  }

  /// Congela el avance: se dejan de empujar posiciones.
  ///
  /// No se usa `duration = -1` porque en am-lyrics eso es un *reset*
  /// (ver `updated()` de AmLyrics: pone `currentTime = 0` y limpia las
  /// líneas activas), no una pausa.
  Future<void> pause() {
    _paused = true;
    return Future<void>.value();
  }

  /// Salta a [ms] manteniendo la reproducción.
  Future<void> seek(double ms) => _js('window.__amLyrics.currentTime = $ms;');

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _ctrl);
}
