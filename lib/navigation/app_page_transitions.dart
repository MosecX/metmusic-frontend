import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transiciones de página compartidas de MetMusic.
///
/// Todas las rutas de detalle empujan con el mismo gesto —desplazamiento
/// sutil a la izquierda + fundido, curvas easeOutCubic/easeInCubic— para
/// que la navegación se sienta rápida y consistente en toda la app. El
/// player conserva su subida desde abajo (`modalUp`), también centralizada
/// aquí.
class AppPageTransitions {
  AppPageTransitions._();

  static const Duration duration = Duration(milliseconds: 300);

  static const Duration reverseDuration = Duration(milliseconds: 240);

  /// Ruta de detalle: empuje suave hacia la izquierda con fundido.
  static CustomTransitionPage<T> push<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  /// Modal a pantalla completa que sube desde abajo (player).
  static CustomTransitionPage<T> modalUp<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      fullscreenDialog: true,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
