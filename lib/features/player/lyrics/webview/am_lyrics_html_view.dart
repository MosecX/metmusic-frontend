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
/// el WebView nativo: Dart solo empuja updates cada ~250ms.
///
/// Puente Dart <-> iframe:
///   - Dart -> iframe: postMessage JSON (`configure` / `time` / `style`)
///     que index.html escucha en su window.
///   - iframe -> Dart: la iframe despacha un CustomEvent
///     `metmusic-lyrics` en el `document` del host, con el mensaje
///     (ready / debug / error / line-click) en `detail`. Si el dispatch
///     no fuera posible, el shim de index.html cae a postMessage y el
///     listener de `_messageSub` lo recoge.
///
/// La sincronizacion NO depende del handshake `ready`: el Timer de push
/// arranca apenas carga la iframe (las funciones JS ya existen) para que
/// un mensaje perdido no deje las letras congeladas.
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
  final bool initialPlaying;
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
    this.initialPlaying = false,
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

  /// Canal primario iframe -> Dart: la iframe despacha un CustomEvent con
  /// este nombre en el `document` del host (misma origen).
  static const html.EventStreamProvider<html.Event> _emitEvents =
      html.EventStreamProvider<html.Event>('metmusic-lyrics');

  late final String _viewType = 'metmusic-am-lyrics-${_nextViewId++}';
  final html.IFrameElement _iframe = html.IFrameElement()
    ..src = 'assets/assets/lyrics/index.html'
    ..style.border = 'none'
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.backgroundColor = 'transparent'
    ..setAttribute('scrolling', 'no');

  StreamSubscription<html.Event>? _emitSub;
  StreamSubscription<html.MessageEvent>? _messageSub;
  StreamSubscription<html.Event>? _loadSub;
  Timer? _pushTimer;
  Timer? _styleRetryShort;
  Timer? _styleRetryLong;
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
    _pendingPlaying = widget.initialPlaying;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iframe,
    );

    _emitSub = _emitEvents.forTarget(html.window.document).listen(_onDomEmit);
    // Fallback del shim de index.html si el CustomEvent no pudiera
    // despacharse.
    _messageSub = html.window.onMessage.listen(_onMessage);
    _loadSub = _iframe.onLoad.listen((_) {
      widget.onDebug?.call('iframe onLoad fired');
      _configure();
      // El empuje de tiempo NO depende del handshake 'ready': las
      // funciones de index.html ya existen (el IIFE corrio al parsear)
      // y un push temprano es inofensivo. Asi la sincronizacion no
      // puede quedarse muerta por un mensaje perdido.
      _startPushTimer();
      _pushTime();
      // Refuerzo de estilo: idempotente (index.html actualiza el mismo
      // <style> y reintenta si el shadowRoot aun no existe).
      _injectStyle();
      _styleRetryShort = Timer(const Duration(seconds: 2), _injectStyle);
      _styleRetryLong = Timer(const Duration(seconds: 5), _injectStyle);
    });
  }

  @override
  void dispose() {
    // Parar el rAF de la iframe antes de que Flutter la desmonte: sin
    // este push final el loop seguiria corriendo sobre una iframe
    // desprendida.
    _pushTime(playingOverride: false);
    _pushTimer?.cancel();
    _styleRetryShort?.cancel();
    _styleRetryLong?.cancel();
    _configureTimeout?.cancel();
    _loadSub?.cancel();
    _emitSub?.cancel();
    _messageSub?.cancel();
    _iframe.remove();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Puente iframe -> Dart
  // -------------------------------------------------------------------------

  /// Mensajes que la iframe despacha como CustomEvent en el `document`
  /// del host. El evento se crea en el realm de la iframe, asi que se
  /// lee `detail` como dynamic en vez de castear a CustomEvent.
  void _onDomEmit(html.Event event) {
    final dynamic detail = (event as dynamic).detail;
    if (detail is String) {
      _process(detail);
    }
  }

  /// Fallback: mensajes del shim por postMessage.
  void _onMessage(html.MessageEvent event) {
    if (event.source != _iframe.contentWindow) return;
    if (event.origin != html.window.location.origin) return;
    final data = event.data;
    if (data is! String) return;
    _process(data);
  }

  void _process(String raw) {
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(raw) as Map<String, dynamic>;
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
        // Idempotentes: por si el 'ready' llega antes que onLoad.
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

  // -------------------------------------------------------------------------
  // Puente Dart -> iframe (postMessage JSON)
  // -------------------------------------------------------------------------

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
          'timeout: am-lyrics no reporto ready en 5s. '
          'Revisar am-lyrics y su iife en la iframe.',
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

  void _pushTime({bool? playingOverride}) {
    final playing = playingOverride ?? _pendingPlaying;
    _post({
      'type': 'time',
      'ms': _pendingMs,
      'playing': playing,
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
