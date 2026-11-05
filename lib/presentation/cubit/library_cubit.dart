import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/library_storage.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LibraryStorage storage;

  static const _maxRecent = 30;

  LibraryCubit(this.storage) : super(const LibraryState());

  Future<void> load() async {
    try {
      final favorites = await storage.readFavorites();
      final recent = await storage.readRecent();
      emit(LibraryState(favorites: favorites, recent: recent));
    } catch (_) {
      // Keep empty state.
    }
  }

  bool isFavorite(String trackId) => state.isFavorite(trackId);

  Future<void> toggleFavorite(Track track) async {
    final favorites = List<Track>.from(state.favorites);
    if (favorites.any((t) => t.id == track.id)) {
      favorites.removeWhere((t) => t.id == track.id);
    } else {
      favorites.insert(0, track);
    }
    emit(state.copyWith(favorites: favorites));
    await storage.saveFavorites(favorites);
  }

  /// Called by the player when a track starts — moves it to the top of the
  /// recently-played list (de-duplicated).
  Future<void> recordPlayed(Track track) async {
    final recent = List<Track>.from(state.recent)
      ..removeWhere((t) => t.id == track.id);
    recent.insert(0, track);
    if (recent.length > _maxRecent) {
      recent.removeRange(_maxRecent, recent.length);
    }
    emit(state.copyWith(recent: recent));
    await storage.saveRecent(recent);
  }
}
