import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';

/// Artwork del reproductor, compartido entre MiniPlayer y FullPlayerScreen.
///
/// Cuando [heroTag] no es null se envuelve en un [Hero] para la transición
/// de expansión del reproductor.
class PlayerArtwork extends StatelessWidget {
  const PlayerArtwork({
    super.key,
    required this.url,
    required this.size,
    this.radius = 12,
    this.heroTag,
    this.heroEnabled = true,
    this.elevated = false,
  });

  final String url;
  final double size;
  final double radius;
  final String? heroTag;
  final bool heroEnabled;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    // Decodificar al tamaño real en píxeles de la pantalla: con un factor fijo
    // de 2 el artwork grande salía reescalado desde un bitmap chico.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (size * dpr).round();

    final content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const _Fallback()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              // Sin el cross-fade por defecto de CachedNetworkImage: durante los
              // 500 ms del fade se componía un frame a medio decodificar y la
              // imagen se veía "cortada" en diagonal (pasaba sobre todo con los
              // artworks de Spotify).
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              filterQuality: FilterQuality.medium,
              memCacheWidth: cacheWidth,
              placeholder: (_, __) => const _Fallback(),
              errorWidget: (_, __, ___) => const _Fallback(),
            ),
    );

    if (heroTag == null || !heroEnabled) return content;
    return Hero(
      tag: heroTag!,
      // El artwork grande no debe deformarse durante el vuelo.
      flightShuttleBuilder: (_, animation, __, ___, toHeroContext) {
        return FadeTransition(opacity: animation, child: toHeroContext.widget);
      },
      child: content,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.05),
      child: LayoutBuilder(
        builder: (context, constraints) => Icon(
          LucideIcons.music,
          size: (constraints.maxWidth * 0.4).clamp(14, 64),
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
