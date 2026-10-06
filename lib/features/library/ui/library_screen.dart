import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/user_playlist.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_placeholder.dart';
import '../../../core/widgets/track_row.dart';
import '../../../navigation/routes.dart';
import '../../player/providers/playback_actions.dart';
import '../../player/providers/player_provider.dart';
import '../models/library_models.dart';
import '../providers/library_provider.dart';

/// Biblioteca: playlists propias, favoritos e historial.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: LibraryTab.values.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(libraryTabProvider.notifier).state =
            LibraryTab.values[_tabs.index];
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El MiniPlayer vive en el `bottomNavigationBar` del `MainShell`, así que
    // tapa el borde inferior del contenido. El botón "Nueva" tiene que subir
    // cuando hay reproducción, si no el player se lo come.
    final hasTrack = ref.watch(hasActiveTrackProvider);
    final miniPlayerOffset = hasTrack
        ? AppConstants.miniPlayerHeight + AppConstants.miniPlayerBottomGap
        : 0.0;

    return Stack(
      children: [
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Text('Tu biblioteca', style: AppTextStyles.headline),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              tabs: [
                for (final tab in LibraryTab.values) Tab(text: tab.label),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _PlaylistsTab(),
                  _FavoritesTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 100 + miniPlayerOffset,
          child: FloatingActionButton.extended(
            heroTag: 'library-create-playlist',
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            elevation: 0,
            onPressed: () => _createPlaylist(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Nueva'),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9)),
        ),
      ],
    );
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final name = await _promptText(context, title: 'Nueva playlist');
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(userPlaylistsProvider.notifier)
          .create(CreatePlaylistDraft(name: name.trim()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playlist creada')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la playlist')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Playlists
// ---------------------------------------------------------------------------

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(userPlaylistsProvider);

    return playlists.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerTrackList(count: 6),
      ),
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.read(userPlaylistsProvider.notifier).refresh(),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.listMusic,
            title: 'Todavía no tenés playlists',
            subtitle: 'Creá una con el botón "Nueva".',
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.backgroundAlt,
          onRefresh: () => ref.read(userPlaylistsProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 170),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _PlaylistTile(
              playlist: items[index],
              onTap: () =>
                  context.push(Routes.userPlaylistPath(items[index].id)),
              onLongPress: () => _showMenu(context, ref, items[index]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    UserPlaylist playlist,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaylistMenu(name: playlist.name),
    );
    if (!context.mounted || action == null) return;

    switch (action) {
      case 'rename':
        final name = await _promptText(
          context,
          title: 'Renombrar playlist',
          initial: playlist.name,
        );
        if (name == null || name.trim().isEmpty) return;
        await ref
            .read(userPlaylistsProvider.notifier)
            .rename(playlist.id, name.trim());
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar playlist'),
            content: Text('¿Eliminar "${playlist.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.danger),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await ref.read(userPlaylistsProvider.notifier).delete(playlist.id);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo eliminar')),
            );
          }
        }
        break;
    }
  }
}

class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.playlist,
    required this.onTap,
    required this.onLongPress,
  });

  final UserPlaylist playlist;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Icon(LucideIcons.listMusic,
                size: 22, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 3),
                Text(
                  '${playlist.numberOfTracks} canciones',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onLongPress,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(LucideIcons.moreVertical,
                  size: 18, color: AppColors.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistMenu extends StatelessWidget {
  const _PlaylistMenu({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.listMusic),
                title: Text(name, style: AppTextStyles.body),
                subtitle: const Text('Opciones de playlist'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.refreshCw, size: 18),
                title: const Text('Renombrar'),
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2,
                    size: 18, color: AppColors.danger),
                title: const Text('Eliminar',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favoritos
// ---------------------------------------------------------------------------

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);
    final currentId = ref.watch(playerProvider).track?.trackId;
    final playing = ref.watch(playerProvider.select((s) => s.playing));

    return favorites.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerTrackList(count: 6),
      ),
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.read(favoritesListProvider.notifier).refresh(),
      ),
      data: (tracks) {
        if (tracks.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.heartOff,
            title: 'Sin favoritos',
            subtitle: 'Marcá canciones con el corazón ❤️',
          );
        }
        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.backgroundAlt,
          onRefresh: () => ref.read(favoritesListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 170),
            children: [
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < tracks.length; i++)
                      TrackRow(
                        track: tracks[i],
                        isActive: tracks[i].trackId == currentId,
                        isPlaying: playing,
                        onTap: () => ref.playTrack(
                          tracks[i],
                          context: tracks,
                          index: i,
                        ),
                        trailing: IconButton(
                          tooltip: 'Quitar de favoritos',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => ref
                              .read(favoritesListProvider.notifier)
                              .remove(tracks[i].trackId),
                          icon: const Icon(LucideIcons.heart,
                              size: 16, color: AppColors.accent),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Historial
// ---------------------------------------------------------------------------

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyListProvider);

    return history.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerTrackList(count: 6),
      ),
      error: (error, _) => ErrorState(
        error: error,
        onRetry: () => ref.read(historyListProvider.notifier).refresh(),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.history,
            title: 'Historial vacío',
            subtitle: 'Lo que escuches va a aparecer acá.',
          );
        }

        final tracks = entries
            .where((e) => e.track != null)
            .map((e) => e.track!)
            .toList(growable: false);

        return RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.backgroundAlt,
          onRefresh: () => ref.read(historyListProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 170),
            children: [
              Row(
                children: [
                  Text('${entries.length} reproducciones',
                      style: AppTextStyles.caption),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmClear(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    icon: const Icon(LucideIcons.trash2, size: 15),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      _HistoryRow(
                        entry: entries[i],
                        onTap: entries[i].track == null
                            ? null
                            : () => ref.playTrack(
                                  entries[i].track!,
                                  context: tracks,
                                  index: tracks.indexOf(entries[i].track!),
                                ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Borrar todo el historial de reproducción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(historyListProvider.notifier).clear();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo limpiar el historial')),
        );
      }
    }
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, this.onTap});

  final HistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              const Icon(LucideIcons.clock,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.artist} • ${_relative(entry.playedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (entry.playedMs > 0)
                Text(
                  DurationFormatter.long(
                      Duration(milliseconds: entry.playedMs)),
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? initial,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Nombre'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
