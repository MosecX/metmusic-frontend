import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Control segmentado estilo iOS: pista gris con píldora activa blanca.
///
/// Se usa para los tipos de búsqueda y los tabs de la biblioteca.
class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.fontSize = 13.5,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Tamaño del texto (12 para filtros de búsqueda, 13.5 por defecto).
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.controlFill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                selected: i == selectedIndex,
                fontSize: fontSize,
                onTap: i == selectedIndex ? null : () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.fontSize,
    this.onTap,
  });

  final String label;
  final bool selected;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.95)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : AppColors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }
}
