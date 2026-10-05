import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/artist.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Card circular de artista.
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    this.size = 116,
    this.onTap,
    this.showName = true,
  });

  final Artist artist;
  final double size;
  final VoidCallback? onTap;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final imageUrl = artist.imageUrl;
    return SizedBox(
      width: size + 12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: AppColors.glassBorder, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const Icon(LucideIcons.user,
                      size: 32, color: AppColors.textTertiary)
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: (size * 2).round(),
                      placeholder: (_, __) => const Icon(LucideIcons.user,
                          size: 32, color: AppColors.textTertiary),
                      errorWidget: (_, __, ___) => const Icon(LucideIcons.user,
                          size: 32, color: AppColors.textTertiary),
                    ),
            ),
            if (showName) ...[
              const SizedBox(height: 10),
              Text(
                artist.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
