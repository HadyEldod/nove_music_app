import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final MusicRepository repository;

  PlaylistsCubit(this.repository) : super(PlaylistsInitial());

  Future<void> load() async {
    emit(PlaylistsLoading());
    try {
      final playlists = await repository.getPlaylists();
      emit(PlaylistsSuccess(playlists));
    } catch (e) {
      emit(PlaylistsError(e.toString()));
    }
  }
}
