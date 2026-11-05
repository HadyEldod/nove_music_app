import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/albums_state.dart';

class AlbumsCubit extends Cubit<AlbumsState> {
  final MusicRepository repository;

  AlbumsCubit(this.repository) : super(AlbumsInitial());

  Future<void> load() async {
    emit(AlbumsLoading());
    try {
      final albums = await repository.getAlbums();
      emit(AlbumsSuccess(albums));
    } catch (e) {
      emit(AlbumsError(e.toString()));
    }
  }
}
