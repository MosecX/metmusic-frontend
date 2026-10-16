import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Centra el contenido y lo limita a [maxWidth] cuando la pantalla es ancha
/// (web/escritorio/tablet). En teléfono devuelve [child] tal cual, así que no
/// hay ningún cambio de layout donde el ancho no lo pida.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width <= maxWidth) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
