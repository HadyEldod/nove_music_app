import 'package:musicc/domain/repositories/music_repository.dart';

/// Shared cache for playlist cover images (derived from the first track).
/// Keyed by playlist id so covers are fetched once across list and grid views.
class PlaylistCover {
  PlaylistCover._();

  static final Map<String, Future<String?>> _cache = {};

  static Future<String?> of(MusicRepository repository, String playlistId) {
    return _cache.putIfAbsent(
      playlistId,
      () => repository.getPlaylistCover(playlistId),
    );
  }
}
