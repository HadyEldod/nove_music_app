import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/track.dart';

class LibraryState extends Equatable {
  final List<Track> favorites;
  final List<Track> recent;

  const LibraryState({
    this.favorites = const [],
    this.recent = const [],
  });

  bool isFavorite(String trackId) =>
      favorites.any((t) => t.id == trackId);

  LibraryState copyWith({List<Track>? favorites, List<Track>? recent}) {
    return LibraryState(
      favorites: favorites ?? this.favorites,
      recent: recent ?? this.recent,
    );
  }

  @override
  List<Object?> get props => [favorites, recent];
}
