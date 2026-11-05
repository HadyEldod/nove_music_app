import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/artist.dart';

abstract class ArtistsState extends Equatable {
  const ArtistsState();

  @override
  List<Object?> get props => [];
}

class ArtistsInitial extends ArtistsState {}

class ArtistsLoading extends ArtistsState {}

class ArtistsSuccess extends ArtistsState {
  final List<Artist> artists;

  const ArtistsSuccess(this.artists);

  @override
  List<Object?> get props => [artists];
}

class ArtistsError extends ArtistsState {
  final String message;

  const ArtistsError(this.message);

  @override
  List<Object?> get props => [message];
}
