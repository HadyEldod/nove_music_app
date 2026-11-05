import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/music_state.dart';

class MusicCubit extends Cubit<MusicState> {
  final MusicRepository repository;

  MusicCubit(this.repository)
      : super(MusicInitial());

  String _query = '';
  String _order = 'popularity_total';

  String get query => _query;
  String get order => _order;

  Future<void> getTracks({String? query, String? order}) async {
    _query = query ?? _query;
    _order = order ?? _order;
    emit(MusicLoading());

    try {
      final tracks = await repository.getTracks(query: _query, order: _order);

      emit(MusicSuccess(tracks));
    } catch (e) {
      emit(
        MusicError(
          e.toString(),
        ),
      );
    }
  }

  /// Re-load with a different ordering (used by the home category chips),
  /// resetting any active text search.
  Future<void> setOrder(String order) => getTracks(query: '', order: order);

  Future<void> search(String query) => getTracks(query: query);

  Future<void> refresh() => getTracks();
}
