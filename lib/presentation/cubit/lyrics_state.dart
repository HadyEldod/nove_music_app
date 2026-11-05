import 'package:equatable/equatable.dart';

abstract class LyricsState extends Equatable {
  const LyricsState();

  @override
  List<Object?> get props => [];
}

class LyricsInitial extends LyricsState {
  const LyricsInitial();
}

class LyricsLoading extends LyricsState {
  const LyricsLoading();
}

/// Lyrics found — [lines] holds one entry per lyric line (blanks included so
/// the paragraph spacing of the original is preserved).
class LyricsLoaded extends LyricsState {
  final List<String> lines;

  const LyricsLoaded(this.lines);

  @override
  List<Object?> get props => [lines];
}

/// No lyrics available for this track (or a lookup error).
class LyricsEmpty extends LyricsState {
  const LyricsEmpty();
}
