// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
//
// dart:html esta deprecado a favor de package:web, pero evita sumar
// dependencias: este archivo solo se compila en builds web dart2js/js
// (el import condicional de lyrics_sheet.dart lo elige cuando existe
// dart.library.html). En builds wasm no se importa y la hoja usa el
// renderer nativo de Dart.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'am_lyrics_shadow_css.dart';

/// `true` cuando hay una vista de plataforma que hostea am-lyrics en esta
/// plataforma. En web (dart2js/js) la vista es una iframe sobre el canvas
/// de Flutter, con el mismo `assets/lyrics/index.html` del WebView nativo.
const bool amLyricsPlatformViewSupported = true;

/// am-lyrics dentro de una iframe del host web (sustituto de
/// `am_lyrics_webview.dart`, misma API).
///
/// El componente y su loop rAF de 30fps viven en la iframe, igual que en
/// el WebView nativo: Dart solo empuja updates cada ~250ms. El puente
/// cruza en ambos sentidos por `postMessage` (JSON strings):
///   - Dart -> iframe: `configure` / `time` / `style` (ver el listener
///     de index.html).
///   - iframe -> Dart: lo que index.html emite por el shim
///     `AmLyricsBridge` (ready / line-click / error / debug).
///
/// El scroll de las letras lo maneja el navegador dentro de la iframe:
/// los eventos del DOM no pasan por la arena de gestos de Flutter, asi
/// que no hace falta el `EagerGestureRecognizer` del WebView nativo.
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
  static int _nextViewId = 0;

  late final String _viewType = 'metmusic-am-lyrics-${_nextViewId++}';
  final html.IFrameElement _iframe = html.IFrameElement()
    ..src = 'assets/assets/lyrics/index.html'
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'transparent'
    ..setAttribute('scrolling', 'no');

  StreamSubscription<html.Event>? _loadSub;
  StreamSubscription<html.MessageEvent>? _messageSub;
  Timer? _pushTimer;
  bool _ready = false;
  bool _configured = false;
  Timer? _configureTimeout;

  double _pendingMs = 0;
  bool _pendingPlaying = false;

  /// Cada cuanto se empuja el tiempo a la iframe. 250ms = 4 Hz, igual
  /// que en el WebView nativo: el rAF interno interpola entre pushes.
  static const Duration _pushInterval = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _pendingMs = widget.initialPosition.inMilliseconds.toDouble();

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _messageSub = html.window.onMessage.listen(_onMessage);
    _loadSub = _iframe.onLoad.listen((_) {
      widget.onDebug?.call('iframe onLoad fired');
      _configure();
    });
  }

  @override
  void dispose() {
    // Parar el rAF de la iframe antes de que Flutter la desmonte: sin
    // este push final el loop seguiria corriendo sobre una iframe
    // desprendida.
    _post({
      'type': 'time',
      'ms': _pendingMs,
      'playing': false,
    });
    _pushTimer?.cancel();
    _configureTimeout?.cancel();
    _loadSub?.cancel();
    _messageSub?.cancel();
    _iframe.remove();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Puente (postMessage, JSON string en ambos sentidos)
  // -------------------------------------------------------------------------

  void _onMessage(html.MessageEvent event) {
    if (event.source != _iframe.contentWindow) return;
    if (event.origin != html.window.location.origin) return;
    final data = event.data;
    if (data is! String) return;

    final Map<String, dynamic> map;
    try {
      map = jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    switch (map['type'] as String?) {
      case 'line-click':
        final ts = (map['timestamp'] as num).toInt();
        widget.onLineTap?.call(Duration(milliseconds: ts));
        break;
      case 'ready':
        _ready = true;
        _configureTimeout?.cancel();
        widget.onDebug?.call('am-lyrics ready');
        _startPushTimer();
        _pushTime();
        _injectStyle();
        break;
      case 'error':
        widget.onError?.call((map['message'] as String?) ?? 'unknown');
        break;
      case 'debug':
        widget.onDebug?.call((map['message'] as String?) ?? 'debug');
        break;
    }
  }

  void _post(Map<String, Object?> payload) {
    payload['__metmusic'] = true;
    _iframe.contentWindow?.postMessage(jsonEncode(payload), '*');
  }

  void _configure() {
    if (_configured) return;
    _configured = true;

    _configureTimeout = Timer(const Duration(seconds: 5), () {
      if (!_ready) {
        widget.onError?.call(
          'timeout: am-lyrics no se registro en 5s. '
          'Revisar carga de am-lyrics.iife.js en la iframe.',
        );
      }
    });

    _post({
      'type': 'configure',
      'trackId': widget.trackId,
      'apiBase': widget.apiBase,
      'apiToken': widget.apiToken,
      'highlightColor': widget.highlightColor,
      'noBlur': widget.noBlur,
    });
  }

  void _startPushTimer() {
    _pushTimer?.cancel();
    _pushTimer = Timer.periodic(_pushInterval, (_) => _pushTime());
  }

  void _pushTime() {
    if (!_ready) return;
    _post({
      'type': 'time',
      'ms': _pendingMs,
      'playing': _pendingPlaying,
    });
  }

  void _injectStyle() {
    _post({
      'type': 'style',
      'css': amLyricsShadowCss,
    });
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
    _pushTime();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _viewType);
}
