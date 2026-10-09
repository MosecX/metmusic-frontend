import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/artist.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Card circular de artista.
class ArtistCard extends StatefulWidget {
  const ArtistCard({
    super.key,
    required this.artist,
    this.size = 108,
    this.onTap,
    this.showName = true,
  });

  final Artist artist;
  final double size;
  final VoidCallback? onTap;
  final bool showName;

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  /// Índice dentro de `artist.imageUrlCandidates`.
  ///
  /// El catálogo a veces sirve una `picture` que da 404 y la imagen nunca
  /// aparece; se prueban las demás thumbs antes de rendirse.
  int _candidate = 0;

  void _nextCandidate() {
    final total = widget.artist.imageUrlCandidates.length;
    if (_candidate + 1 < total) setState(() => _candidate++);
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.artist.imageUrlCandidates;
    final imageUrl = candidates.isEmpty ? '' : candidates[_candidate];

    return SizedBox(
      width: widget.size + 12,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.size),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundAlt,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const _ArtistFallback()
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      // El cross-fade por defecto componía un frame a medio
                      // decodificar y deformaba la imagen en diagonal.
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      filterQuality: FilterQuality.medium,
                      memCacheWidth: (widget.size * 2).round(),
                      placeholder: (_, __) => const _ArtistFallback(),
                      errorWidget: (_, __, ___) {
                        // `errorWidget` no puede disparar setState durante el
                        // build, así que se agenda para el próximo frame.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _nextCandidate();
                        });
                        return const _ArtistFallback();
                      },
                    ),
            ),
            if (widget.showName) ...[
              const SizedBox(height: 9),
              Text(
                widget.artist.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArtistFallback extends StatelessWidget {
  const _ArtistFallback();

  @override
  Widget build(BuildContext context) =>
      const Icon(LucideIcons.user, size: 32, color: AppColors.textTertiary);
}
