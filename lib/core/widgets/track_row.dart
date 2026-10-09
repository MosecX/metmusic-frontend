import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/track.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/duration_formatter.dart';

/// Fila de canción reutilizable (búsqueda, álbum, historial, favoritos).
///
/// Estilo boceto: `número/EQ · portada 46 · título+artista · duración`,
/// filas planas sobre el fondo (sin card).
class TrackRow extends StatefulWidget {
  const TrackRow({
    super.key,
    required this.track,
    this.index,
    this.isActive = false,
    this.isPlaying = false,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.showAlbum = false,
    this.showArtwork = true,
    this.padding = EdgeInsets.zero,
  });

  final Track track;

  /// Número de pista mostrado a la izquierda (siempre que se indique).
  final int? index;
  final bool isActive;
  final bool isPlaying;
  final VoidCallback? onTap;

  /// Abre el menú de contexto de la pista (long-press).
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showAlbum;
  final bool showArtwork;
  final EdgeInsetsGeometry padding;

  @override
  State<TrackRow> createState() => _TrackRowState();
}

class _TrackRowState extends State<TrackRow> {
  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final accent = widget.isActive ? AppColors.accent : AppColors.textPrimary;
    final showEq = widget.isActive && widget.isPlaying;

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: widget.padding,
        child: Row(
          children: [
            if (widget.index != null) ...[
              SizedBox(
                width: 22,
                child: Center(
                  child: showEq
                      ? const _EqBars()
                      : Text(
                          '${widget.index}',
                          style: AppTextStyles.rowTrailing.copyWith(
                            color: widget.isActive
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
            ],
            if (widget.showArtwork) ...[
              _Artwork(track: track),
              const SizedBox(width: 13),
            ],
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
                          style: AppTextStyles.rowTitle.copyWith(color: accent),
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
                  const SizedBox(height: 1),
                  Text(
                    widget.showAlbum && track.album != null
                        ? '${track.artist ?? ''} • ${track.album}'
                        : (track.artist ?? 'Desconocido'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.rowSubtitle,
                  ),
                ],
              ),
            ),
            if (widget.trailing != null && track.durationSeconds > 0) ...[
              const SizedBox(width: 8),
              Text(
                DurationFormatter.format(track.duration),
                style: AppTextStyles.rowTrailing,
              ),
            ],
            if (widget.trailing != null) ...[
              const SizedBox(width: 4),
              widget.trailing!,
            ] else if (track.durationSeconds > 0) ...[
              const SizedBox(width: 8),
              Text(
                DurationFormatter.format(track.duration),
                style: AppTextStyles.rowTrailing,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ecualizador animado de 3 barras para la fila en reproducción.
class _EqBars extends StatefulWidget {
  const _EqBars();

  @override
  State<_EqBars> createState() => _EqBarsState();
}

class _EqBarsState extends State<_EqBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // Alturas base (60% / 100% / 40% de 14px, como el boceto).
  static const List<double> _heights = [8.4, 14, 5.6];
  static const List<Interval> _phases = [
    Interval(0.0, 0.5, curve: Curves.easeInOut),
    Interval(0.3, 0.8, curve: Curves.easeInOut),
    Interval(0.5, 1.0, curve: Curves.easeInOut),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _heights.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Transform.scale(
                  scaleY: 0.4 + 0.6 * _phases[i].transform(_controller.value),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 3,
                    height: _heights[i],
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final url = track.listThumbnailUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 46,
        height: 46,
        child: url.isEmpty
            ? const _ArtworkFallback()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                filterQuality: FilterQuality.medium,
                memCacheWidth: 160,
                placeholder: (_, __) => const _ArtworkFallback(),
                errorWidget: (_, __, ___) => const _ArtworkFallback(),
              ),
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
