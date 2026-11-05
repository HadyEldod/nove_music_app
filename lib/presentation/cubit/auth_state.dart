import 'package:equatable/equatable.dart';

import 'package:musicc/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Guest mode — the app works fully without signing in.
class AuthLoggedOut extends AuthState {
  /// A message shown after a failed sign-in attempt, if any.
  final String? error;

  const AuthLoggedOut({this.error});

  @override
  List<Object?> get props => [error];
}

class AuthLoading extends AuthState {}

class AuthLoggedIn extends AuthState {
  final User user;

  const AuthLoggedIn(this.user);

  @override
  List<Object?> get props => [user];
}
