import 'package:equatable/equatable.dart';
import 'package:musicc/domain/entities/track.dart';


abstract class MusicState extends Equatable {
  const MusicState();

  @override
  List<Object?> get props => [];
}

class MusicInitial extends MusicState {}

class MusicLoading extends MusicState {}

class MusicSuccess extends MusicState {
  final List<Track> tracks;

  const MusicSuccess(this.tracks);

  @override
  List<Object?> get props => [tracks];
}

class MusicError extends MusicState {
  final String message;

  const MusicError(this.message);

  @override
  List<Object?> get props => [message];
}
