import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/album.dart';
import '../../../core/models/explore.dart';
import '../../../core/models/history_entry.dart';
import '../../../core/models/track.dart';
import '../../../services/api/explore_service.dart';
import '../../../services/service_providers.dart';

/// Datos agregados de la pantalla Home.
class HomeData {
  const HomeData({
    this.recent = const [],
    this.newReleases = const [],
    this.charts = const [],
    this.editorial = const [],
    this.explore = const ExploreHome(),
    this.mood,
    this.offline = false,
  });

  final List<HistoryEntry> recent;
  final List<Album> newReleases;
  final List<Track> charts;
  final List<Track> editorial; // placeholder de playlists editoriales si faltan
  final ExploreHome explore;
  final ExploreMood? mood;

  /// True cuando el backend no respondió y se muestran datos locales.
  final bool offline;

  bool get isEmpty =>
      recent.isEmpty && newReleases.isEmpty && charts.isEmpty && explore.isEmpty;
}

/// Controlador de la Home: combina `/api/explore/*` con el historial local.
class HomeController extends AsyncNotifier<HomeData> {
  @override
  Future<HomeData> build() => _load();

  Future<HomeData> _load({ExploreMood? mood}) async {
    final exploreService = ref.read(exploreServiceProvider);
    final history = ref.read(historyServiceProvider);

    // El historial local se muestra siempre (aunque no haya red).
    final recent = history.recentDistinct(limit: 10);

    try {
      final results = await Future.wait<dynamic>([
        exploreService.getHome(mood: mood),
        exploreService.getNewReleases(limit: 20),
        exploreService.getCharts(limit: 20),
      ]);

      final explore = results[0] as ExploreHome;
      final newReleases = results[1] as List<Album>;
      final charts = results[2] as List<Track>;

      return HomeData(
        recent: recent,
        newReleases: newReleases.isNotEmpty ? newReleases : _albumsFrom(explore),
        charts: charts.isNotEmpty ? charts : _tracksFrom(explore),
        explore: explore,
        mood: mood,
      );
    } catch (error) {
      // Sin red: devolvemos lo local; si no hay nada, propagamos el error.
      if (recent.isEmpty) rethrow;
      return HomeData(recent: recent, offline: true);
    }
  }

  /// Cambia el mood y recarga la Home.
  Future<void> setMood(ExploreMood? mood) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(mood: mood));
  }

  /// Pull-to-refresh.
  Future<void> refresh() async {
    final mood = state.valueOrNull?.mood;
    state = await AsyncValue.guard(() => _load(mood: mood));
  }

  List<Album> _albumsFrom(ExploreHome home) {
    for (final section in home.sections) {
      if (section.type == ExploreSectionType.albums && section.albums.isNotEmpty) {
        return section.albums;
      }
    }
    return const [];
  }

  List<Track> _tracksFrom(ExploreHome home) {
    for (final section in home.sections) {
      if (section.type == ExploreSectionType.tracks && section.tracks.isNotEmpty) {
        return section.tracks;
      }
    }
    return const [];
  }
}

/// Datos de la Home.
final homeProvider = AsyncNotifierProvider<HomeController, HomeData>(
  HomeController.new,
);

/// Mood activo de la Home (null = default del backend).
final homeMoodProvider = StateProvider<ExploreMood?>((ref) => null);
