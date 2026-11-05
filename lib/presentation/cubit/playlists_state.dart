import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/playlist.dart';

abstract class PlaylistsState extends Equatable {
  const PlaylistsState();

  @override
  List<Object?> get props => [];
}

class PlaylistsInitial extends PlaylistsState {}

class PlaylistsLoading extends PlaylistsState {}

class PlaylistsSuccess extends PlaylistsState {
  final List<Playlist> playlists;

  const PlaylistsSuccess(this.playlists);

  @override
  List<Object?> get props => [playlists];
}

class PlaylistsError extends PlaylistsState {
  final String message;

  const PlaylistsError(this.message);

  @override
  List<Object?> get props => [message];
}
