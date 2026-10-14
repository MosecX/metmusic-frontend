import 'dart:ui';

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
      padding: const EdgeInsets.only(left: 8, top: 6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap ?? () => Navigator.of(context).maybePop(),
            child: const ColoredBox(
              color: AppColors.glassFill,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(LucideIcons.chevronLeft,
                    size: 20, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cabecera de detalle centrada (boceto): hero + título + artista + acciones.
// ---------------------------------------------------------------------------

/// Cabecera de las pantallas de detalle de álbum / artista / playlist.
///
/// Se coloca dentro de un `SliverToBoxAdapter`; el `SliverAppBar` encima
/// sólo aporta el botón atrás y el título de sección.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.imageUrl,
    required this.title,
    this.artist,
    this.meta,
    this.isRound = false,
    this.onArtistTap,
    this.onShuffle,
    this.onPlay,
    this.onMore,
    this.actionsEnabled = true,
  });

  final String imageUrl;
  final String title;
  final String? artist;
  final String? meta;
  final bool isRound;
  final VoidCallback? onArtistTap;
  final VoidCallback? onShuffle;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _HeroArtwork(url: imageUrl, isRound: isRound)),
          const SizedBox(height: 22),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          if (artist != null && artist!.isNotEmpty) ...[
            const SizedBox(height: 6),
            if (onArtistTap != null)
              GestureDetector(
                onTap: onArtistTap,
                child: Text(
                  artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              )
            else
              Text(
                artist!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
          ],
          if (meta != null && meta!.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              meta!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardSubtitle,
            ),
          ],
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onShuffle != null) ...[
                _CircleAction(
                  icon: LucideIcons.shuffle,
                  onTap: actionsEnabled ? onShuffle : null,
                ),
                const SizedBox(width: 34),
              ],
              if (onPlay != null)
                _CircleAction(
                  icon: LucideIcons.play,
                  primary: true,
                  onTap: actionsEnabled ? onPlay : null,
                ),
              if (onMore != null) ...[
                const SizedBox(width: 34),
                _CircleAction(
                  icon: LucideIcons.ellipsis,
                  onTap: onMore,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.url, required this.isRound});

  final String url;
  final bool isRound;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final size = (screenWidth - 96).clamp(170.0, 264.0);
    final borderRadius =
        isRound ? BorderRadius.zero : BorderRadius.circular(12);

    final content = ColoredBox(
      color: Colors.white.withValues(alpha: 0.05),
      child: url.isEmpty
          ? _fallback(size)
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _fallback(size),
              errorWidget: (_, __, ___) => _fallback(size),
            ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: isRound
          ? ClipOval(child: content)
          : ClipRRect(borderRadius: borderRadius, child: content),
    );
  }

  Widget _fallback(double size) => SizedBox(
        width: size,
        height: size,
        child: Icon(
          isRound ? LucideIcons.user : LucideIcons.disc3,
          size: size * 0.28,
          color: AppColors.textTertiary,
        ),
      );
}

/// Botón circular de acciones de la cabecera (shuffle / play / más).
class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: primary ? AppColors.accent : AppColors.glassFill,
        shape: CircleBorder(
          side: primary
              ? BorderSide.none
              : const BorderSide(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              icon,
              size: primary ? 26 : 24,
              color: primary ? Colors.black : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
