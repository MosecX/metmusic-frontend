import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'am_lyrics_shadow_css.dart';

/// `true` cuando hay una vista de plataforma que hostea am-lyrics en esta
/// plataforma. Aca (WebView nativo) es `!kIsWeb`; en los builds web con
/// dart2js/js el import condicional de `lyrics_sheet.dart` trae el valor
/// de `am_lyrics_html_view.dart`; en builds web wasm cae a este archivo y
/// la hoja usa el renderer nativo de Dart.
const bool amLyricsPlatformViewSupported = !kIsWeb;

/// WebView que hostea am-lyrics. El loop de sincronizacion vive DENTRO
/// del WebView (JS con requestAnimationFrame). Dart solo empuja updates
/// cada ~250ms via __setLyricsTime. Eso reduce el cruce del puente
/// Dart-JS de 20-33 Hz a 4 Hz, que es la diferencia entre lag y
/// fluidez en gama baja.
///
/// Solo plataformas nativas: en web lo sustituye `am_lyrics_html_view.dart`
/// (misma API) via el import condicional de `lyrics_sheet.dart`.
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
              unawaited(_injectStyle(amLyricsShadowCss));
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

    final options = jsonEncode({
      'trackId': widget.trackId,
      'apiBase': widget.apiBase,
      'apiToken': widget.apiToken,
      'highlightColor': widget.highlightColor,
      'noBlur': widget.noBlur,
    });

    _configureTimeout = Timer(const Duration(seconds: 5), () {
      if (!_ready) {
        widget.onError?.call(
          'timeout: am-lyrics no se registro en 5s. '
          'Revisar carga de am-lyrics.iife.js en el WebView.',
        );
      }
    });

    // La logica de configuracion vive en index.html
    // (`__configureAmLyrics`): la comparten este WebView y la iframe web
    // del host (am_lyrics_html_view.dart).
    await _ctrl.runJavaScript(
      'window.__configureAmLyrics && window.__configureAmLyrics($options);',
    );
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
