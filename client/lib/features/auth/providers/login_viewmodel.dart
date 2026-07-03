import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';

enum LoginStage { idle, loading, success, error }

class LoginState {
  final LoginStage stage;
  final String? error;

  const LoginState({this.stage = LoginStage.idle, this.error});
}

class LoginViewModel extends AsyncNotifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<void> login(String email, String password) async {
    state = const LoginState(stage: LoginStage.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.login(email, password);
      state = const LoginState(stage: LoginStage.success);
    } catch (e) {
      state = LoginState(
        stage: LoginStage.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const LoginState();
}

final loginViewModelProvider =
    AsyncNotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);
