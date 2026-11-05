import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/auth_storage.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final MusicRepository repository;
  final AuthStorage storage;

  AuthCubit(this.repository, this.storage) : super(const AuthLoggedOut());

  /// Restore a previously signed-in user on startup (silent — falls back to
  /// guest mode on any failure).
  Future<void> restore() async {
    try {
      final username = await storage.readUsername();
      if (username == null || username.isEmpty) return;
      final user = await repository.getUser(username);
      if (user != null) {
        emit(AuthLoggedIn(user));
      }
    } catch (_) {
      // Stay in guest mode.
    }
  }

  Future<void> signIn(String username) async {
    final name = username.trim();
    if (name.isEmpty) {
      emit(const AuthLoggedOut(error: 'Enter a Jamendo username.'));
      return;
    }
    emit(AuthLoading());
    try {
      final user = await repository.getUser(name);
      if (user == null) {
        emit(AuthLoggedOut(error: 'No Jamendo user named "$name".'));
        return;
      }
      await storage.saveUsername(user.name);
      emit(AuthLoggedIn(user));
    } catch (e) {
      emit(const AuthLoggedOut(error: 'Could not sign in. Try again.'));
    }
  }

  Future<void> signOut() async {
    await storage.clear();
    emit(const AuthLoggedOut());
  }
}
