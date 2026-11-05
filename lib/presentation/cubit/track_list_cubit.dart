import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/music_state.dart';

/// Loads a list of tracks from any source (artist catalogue, playlist, …)
/// and reuses [MusicState] so it can share the same list UI.
class TrackListCubit extends Cubit<MusicState> {
  final Future<List<Track>> Function() loader;

  TrackListCubit(this.loader) : super(MusicInitial());

  Future<void> load() async {
    emit(MusicLoading());
    try {
      final tracks = await loader();
      emit(MusicSuccess(tracks));
    } catch (e) {
      emit(MusicError(e.toString()));
    }
  }
}
