import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/track.dart';

abstract class DeviceMusicState extends Equatable {
  const DeviceMusicState();

  @override
  List<Object?> get props => [];
}

class DeviceMusicInitial extends DeviceMusicState {}

class DeviceMusicLoading extends DeviceMusicState {}

/// Permission to read audio was not granted.
class DeviceMusicDenied extends DeviceMusicState {
  final bool permanentlyDenied;

  const DeviceMusicDenied({this.permanentlyDenied = false});

  @override
  List<Object?> get props => [permanentlyDenied];
}

/// Something went wrong while scanning (message shown to help diagnose).
class DeviceMusicError extends DeviceMusicState {
  final String message;

  const DeviceMusicError(this.message);

  @override
  List<Object?> get props => [message];
}

class DeviceMusicLoaded extends DeviceMusicState {
  final List<Track> tracks;

  const DeviceMusicLoaded(this.tracks);

  @override
  List<Object?> get props => [tracks];
}
