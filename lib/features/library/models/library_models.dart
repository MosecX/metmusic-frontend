/// Pestañas de la Library.
enum LibraryTab {
  playlists('Playlists'),
  favorites('Favoritos'),
  mixes('Mixes'),
  history('Historial');

  const LibraryTab(this.label);

  final String label;
}

/// Borrador para crear una playlist.
class CreatePlaylistDraft {
  const CreatePlaylistDraft({
    required this.name,
    this.description,
    this.coverUrl,
  });

  final String name;
  final String? description;
  final String? coverUrl;

  bool get isValid => name.trim().isNotEmpty;
}
