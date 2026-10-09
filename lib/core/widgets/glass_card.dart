import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/glass_styles.dart';

/// Capa de vidrio estilo **Glass 2**: relleno blanco 10% + blur + borde.
///
/// Se usa para cards, secciones, búsqueda, bottom nav y headers.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.fill,
    this.blur = GlassStyles.blurSigma,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? fill;
  final double blur;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? GlassStyles.cardBorderRadius;
    final content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: GlassStyles.cardDecoration(borderRadius: radius, fill: fill),
      // Material transparente propio: los ListTiles/InkWells internos pintan
      // sobre el relleno de la card en vez de quedar ocultos debajo.
      child: Material(type: MaterialType.transparency, child: child),
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: onTap == null
              ? content
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(radius),
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}
