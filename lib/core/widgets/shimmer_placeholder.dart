import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Bloque con animación shimmer para estados de carga.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.10),
        );
  }
}

/// Placeholder de un `TrackRow` mientras carga.
class ShimmerTrackRow extends StatelessWidget {
  const ShimmerTrackRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ShimmerBox(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 180, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 110, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBox(width: 28, height: 12),
        ],
      ),
    );
  }
}

/// Placeholder de una card de álbum mientras carga.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.width = 150});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: width, height: width, borderRadius: 20),
          const SizedBox(height: 10),
          ShimmerBox(width: width * 0.8, height: 12),
          const SizedBox(height: 8),
          ShimmerBox(width: width * 0.5, height: 10),
        ],
      ),
    );
  }
}

/// Fila horizontal de cards shimmer.
class ShimmerRow extends StatelessWidget {
  const ShimmerRow({super.key, this.count = 3, this.cardWidth = 150});

  final int count;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardWidth + 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => ShimmerCard(width: cardWidth),
      ),
    );
  }
}

/// Lista vertical de shimmer tracks.
class ShimmerTrackList extends StatelessWidget {
  const ShimmerTrackList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ShimmerTrackRow()),
    );
  }
}

/// Placeholder genérico con shimmer para uso libre.
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
  });

  final int lines;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ShimmerBox(height: lineHeight, width: i.isEven ? null : 200),
        ),
      ),
    );
  }
}

/// Fondo de gradiente usado detrás de las listas de shimmer.
Widget shimmerScaffoldBackground(BuildContext context) => Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
    );
