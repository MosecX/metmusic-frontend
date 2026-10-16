import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/content_width.dart';
import '../core/widgets/glass_card.dart';
import '../features/player/providers/player_provider.dart';
import '../features/player/ui/mini_player.dart';
import 'routes.dart';

/// Scaffold principal: fondo con gradiente, contenido, MiniPlayer y
/// NavigationBar inferior con estilo Glass 2.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const List<_NavItem> _items = [
    _NavItem(LucideIcons.home, 'Inicio', Routes.home),
    _NavItem(LucideIcons.search, 'Buscar', Routes.search),
    _NavItem(LucideIcons.library, 'Biblioteca', Routes.library),
    _NavItem(LucideIcons.settings, 'Ajustes', Routes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = Routes.indexOf(location);
    final hasTrack = ref.watch(hasActiveTrackProvider);

    // Errores de reproducción → SnackBar global.
    ref.listen(playerProvider.select((s) => s.error), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(next)),
            action: SnackBarAction(
              label: 'Cerrar',
              onPressed: () => ref.read(playerProvider.notifier).dismissError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: ContentWidth(
            maxWidth: AppConstants.contentMaxWidth,
            child: widget.child,
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTrack) const MiniPlayer(),
          _GlassNavBar(
            items: _items,
            currentIndex: currentIndex,
            onSelect: (item) => context.go(item.path),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    final text = error.toString();
    if (text.contains('404')) return 'Track no disponible';
    if (text.contains('502') || text.contains('503')) {
      return 'Error del servidor de música';
    }
    return 'No se pudo reproducir el track';
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.path);

  final IconData icon;
  final String label;
  final String path;
}

/// MiniPlayer para las pantallas que están fuera del [MainShell]
/// (álbum, artista, playlist), para que el reproductor siga visible.
///
/// No muestra nada cuando no hay track en cola. Usarlo como
/// `bottomNavigationBar` de un `Scaffold` con `extendBody: true` deja que el
/// contenido se deslice por debajo, igual que en el shell principal.
class GlobalMiniPlayer extends ConsumerWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrack = ref.watch(hasActiveTrackProvider);
    if (!hasTrack) return const SizedBox.shrink();
    return const MiniPlayer();
  }
}

/// Barra de navegación inferior con estilo Glass 2.
class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<_NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ContentWidth(
        maxWidth: AppConstants.readingMaxWidth,
        child: GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(items[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
