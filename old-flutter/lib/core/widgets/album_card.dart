import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/album.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Card de álbum usada en carruseles horizontales y grids.
class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    this.width = 148,
    this.onTap,
  });

  final Album album;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtwork(album: album, size: width),
            const SizedBox(height: 9),
            Text(
              album.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 2),
            Text(
              [album.artist, if (album.year.isNotEmpty) album.year]
                  .whereType<String>()
                  .where((e) => e.isNotEmpty)
                  .join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Artwork cuadrado con fallback (radio de arte: 10).
class AlbumArtwork extends StatelessWidget {
  const AlbumArtwork({
    super.key,
    required this.album,
    required this.size,
    this.radius = 10,
  });

  final Album album;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      clipBehavior: Clip.antiAlias,
      child: album.thumbnailUrl.isEmpty
          ? const ArtworkPlaceholder()
          : CachedNetworkImage(
              imageUrl: album.thumbnailUrl,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              filterQuality: FilterQuality.medium,
              memCacheWidth: (size * 2).round(),
              placeholder: (_, __) => const ArtworkPlaceholder(),
              errorWidget: (_, __, ___) => const ArtworkPlaceholder(),
            ),
    );
  }
}

/// Placeholder de artwork reutilizable.
class ArtworkPlaceholder extends StatelessWidget {
  const ArtworkPlaceholder({super.key, this.iconSize = 32});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.04),
      child: Icon(
        LucideIcons.disc3,
        size: iconSize,
        color: AppColors.textTertiary,
      ),
    );
  }
}
