import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/playlist.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/glass_styles.dart';

/// Card de playlist (editorial o de usuario).
class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    this.width = 152,
    this.onTap,
    this.onLongPress,
  });

  final Playlist playlist;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(GlassStyles.cardBorderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PlaylistCover(url: playlist.thumbnailUrl, size: width),
            const SizedBox(height: 10),
            Text(
              playlist.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (playlist.creator != null && playlist.creator!.isNotEmpty) {
      parts.add(playlist.creator!);
    }
    if (playlist.trackCount > 0) parts.add('${playlist.trackCount} canciones');
    return parts.join(' • ');
  }
}

/// Portada cuadrada con borde de vidrio.
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GlassStyles.cardBorderRadius),
        border: Border.all(color: AppColors.glassBorder),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Icon(LucideIcons.listMusic,
              size: 30, color: AppColors.textTertiary)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              filterQuality: FilterQuality.medium,
              memCacheWidth: (size * 2).round(),
              placeholder: (_, __) => const Icon(LucideIcons.listMusic,
                  size: 30, color: AppColors.textTertiary),
              errorWidget: (_, __, ___) => const Icon(LucideIcons.listMusic,
                  size: 30, color: AppColors.textTertiary),
            ),
    );
  }
}
