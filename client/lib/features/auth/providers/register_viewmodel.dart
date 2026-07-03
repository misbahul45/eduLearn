import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';

enum RegisterStage { idle, loading, success, error }

class RegisterState {
  final RegisterStage stage;
  final String? error;

  const RegisterState({this.stage = RegisterStage.idle, this.error});
}

class RegisterViewModel extends Notifier<RegisterState> {
  @override
  RegisterState build() => const RegisterState();

  Future<void> register(String name, String email, String password) async {
    state = const RegisterState(stage: RegisterStage.loading);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.register(name, email, password);
      state = const RegisterState(stage: RegisterStage.success);
    } catch (e) {
      state = RegisterState(
        stage: RegisterStage.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const RegisterState();
}

final registerViewModelProvider =
    NotifierProvider<RegisterViewModel, RegisterState>(RegisterViewModel.new);
