import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_status.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_repository.dart';

enum AuthFormStage { idle, loading, success, error }

class AuthFormState {
  final AuthFormStage stage;
  final AuthStatus? authStatus;
  final String? error;

  const AuthFormState({
    this.stage = AuthFormStage.idle,
    this.authStatus,
    this.error,
  });

  AuthFormState copyWith({
    AuthFormStage? stage,
    AuthStatus? authStatus,
    String? error,
  }) {
    return AuthFormState(
      stage: stage ?? this.stage,
      authStatus: authStatus ?? this.authStatus,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthFormState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthFormState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(stage: AuthFormStage.loading, error: null);
    try {
      final status = await _repository.login(email, password);
      state = AuthFormState(stage: AuthFormStage.success, authStatus: status);
    } catch (e) {
      state = state.copyWith(
        stage: AuthFormStage.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(stage: AuthFormStage.loading, error: null);
    try {
      final status = await _repository.register(name, email, password);
      state = AuthFormState(stage: AuthFormStage.success, authStatus: status);
    } catch (e) {
      state = state.copyWith(
        stage: AuthFormStage.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthFormState();
  }

  void reset() {
    state = const AuthFormState();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthFormState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
