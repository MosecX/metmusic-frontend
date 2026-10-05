import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/duration_formatter.dart';

/// Fila de canción reutilizable (búsqueda, álbum, historial, favoritos).
class TrackRow extends StatelessWidget {
  const TrackRow({
    super.key,
    required this.track,
    this.index,
    this.isActive = false,
    this.isPlaying = false,
    this.onTap,
    this.onPlayTap,
    this.trailing,
    this.showAlbum = false,
    this.showArtwork = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
  });

  final Track track;

  /// Número de pista mostrado a la izquierda (si no hay artwork).
  final int? index;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final Widget? trailing;
  final bool showAlbum;
  final bool showArtwork;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final accent = isActive ? AppColors.accent : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (showArtwork)
              _Artwork(track: track, isActive: isActive)
            else if (index != null)
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    '$index',
                    style: AppTextStyles.caption.copyWith(color: accent),
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          track.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(color: accent),
                        ),
                      ),
                      if (track.explicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('E', style: AppTextStyles.caption),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    showAlbum && track.album != null
                        ? '${track.artist ?? ''} • ${track.album}'
                        : (track.artist ?? 'Desconocido'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                (onPlayTap != null
                    ? IconButton(
                        onPressed: onPlayTap,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isActive && isPlaying
                              ? LucideIcons.pause
                              : LucideIcons.play,
                          size: 18,
                          color: isActive ? AppColors.accent : AppColors.textSecondary,
                        ),
                      )
                    : Text(
                        DurationFormatter.format(track.duration),
                        style: AppTextStyles.caption,
                      )),
            if (trailing != null && track.durationSeconds > 0) ...[
              const SizedBox(width: 8),
              Text(
                DurationFormatter.format(track.duration),
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track, required this.isActive});

  final Track track;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final url = track.listThumbnailUrl;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.accent : AppColors.glassBorder,
          width: isActive ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const _ArtworkFallback()
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 160,
              placeholder: (_, __) => const _ArtworkFallback(),
              errorWidget: (_, __, ___) => const _ArtworkFallback(),
            ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(
        LucideIcons.music,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}
