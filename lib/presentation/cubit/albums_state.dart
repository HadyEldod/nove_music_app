import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/album.dart';

abstract class AlbumsState extends Equatable {
  const AlbumsState();

  @override
  List<Object?> get props => [];
}

class AlbumsInitial extends AlbumsState {}

class AlbumsLoading extends AlbumsState {}

class AlbumsSuccess extends AlbumsState {
  final List<Album> albums;

  const AlbumsSuccess(this.albums);

  @override
  List<Object?> get props => [albums];
}

class AlbumsError extends AlbumsState {
  final String message;

  const AlbumsError(this.message);

  @override
  List<Object?> get props => [message];
}
