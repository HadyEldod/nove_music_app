import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/data/datasources/lyrics_remote_data_source.dart';
import 'package:musicc/presentation/cubit/lyrics_state.dart';

/// Loads lyrics for a track and caches results per "artist|title" so switching
/// between tracks and back doesn't re-hit the network.
class LyricsCubit extends Cubit<LyricsState> {
  final LyricsRemoteDataSource dataSource;

  final Map<String, List<String>> _cache = {};
  String? _currentKey;

  LyricsCubit(this.dataSource) : super(const LyricsInitial());

  Future<void> load({required String artist, required String title}) async {
    final key = '$artist|$title';
    if (key == _currentKey && state is! LyricsInitial) return;
    _currentKey = key;

    final cached = _cache[key];
    if (cached != null) {
      emit(cached.isEmpty ? const LyricsEmpty() : LyricsLoaded(cached));
      return;
    }

    emit(const LyricsLoading());
    final lines = await dataSource.getLyrics(artist: artist, title: title);
    // Ignore a stale response if the user already moved to another track.
    if (_currentKey != key) return;
    _cache[key] = lines;
    emit(lines.isEmpty ? const LyricsEmpty() : LyricsLoaded(lines));
  }
}
