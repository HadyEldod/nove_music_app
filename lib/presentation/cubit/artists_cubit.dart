import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/artists_state.dart';

class ArtistsCubit extends Cubit<ArtistsState> {
  final MusicRepository repository;

  ArtistsCubit(this.repository) : super(ArtistsInitial());

  String _query = '';

  Future<void> load({String? query}) async {
    _query = query ?? _query;
    emit(ArtistsLoading());
    try {
      final artists = await repository.getArtists(query: _query);
      emit(ArtistsSuccess(artists));
    } catch (e) {
      emit(ArtistsError(e.toString()));
    }
  }

  Future<void> search(String query) => load(query: query);
}
