import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Encabezado colapsable usado por los detalles de álbum, artista y playlist.
///
/// Se coloca como `flexibleSpace.background` de un [SliverAppBar].
class CollapsibleHeader extends StatelessWidget {
  const CollapsibleHeader({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.meta,
    this.isRound = false,
    this.imageSize = 156,
  });

  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? meta;

  /// True para artistas (avatar circular).
  final bool isRound;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xAA0A0A0F), Color(0xF20A0A0F)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Artwork(
                  url: imageUrl,
                  isRound: isRound,
                  size: imageSize,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (meta != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(meta!.toUpperCase(),
                                style: AppTextStyles.overline),
                          ),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.url,
    required this.isRound,
    required this.size,
  });

  final String url;
  final bool isRound;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isRound ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRound ? null : BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(
              isRound ? LucideIcons.user : LucideIcons.disc3,
              size: size * 0.28,
              color: AppColors.textTertiary,
            )
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => Icon(
                isRound ? LucideIcons.user : LucideIcons.disc3,
                size: size * 0.28,
                color: AppColors.textTertiary,
              ),
            ),
    );
  }
}

/// Botón circular de vidrio para el leading del SliverAppBar.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.chevronLeft, size: 20),
          ),
        ),
      ),
    );
  }
}
