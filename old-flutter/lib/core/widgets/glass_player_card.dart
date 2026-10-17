import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_styles.dart';

/// Capa de vidrio estilo **Glass 1**: relleno blanco 10% + blur + borde.
///
/// Se usa EXCLUSIVAMENTE para el MiniPlayer, el FullPlayerScreen y el
/// QueueSheet.
class GlassPlayerCard extends StatelessWidget {
  const GlassPlayerCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = GlassStyles.blurSigma,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double blur;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? GlassStyles.playerBorderRadius;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: GlassStyles.playerDecoration(borderRadius: radius),
            child: child,
          ),
        ),
      ),
    );
  }
}
