import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_providers.dart';

enum SplashStage { initial, checking, authenticated, unauthenticated }

class SplashState {
  final SplashStage stage;
  final String? error;

  const SplashState({this.stage = SplashStage.initial, this.error});

  SplashState copyWith({SplashStage? stage, String? error}) {
    return SplashState(stage: stage ?? this.stage, error: error);
  }
}

class SplashNotifier extends Notifier<SplashState> {
  @override
  SplashState build() => const SplashState();

  Future<SplashStage> check() async {
    debugPrint('[SplashProvider] check() called');
    state = state.copyWith(stage: SplashStage.checking);

    try {
      final repository = ref.read(authRepositoryProvider);
      debugPrint('[SplashProvider] Calling repository.checkAuth()...');
      final status = await repository.checkAuth()
          .timeout(const Duration(seconds: 5));
      debugPrint('[SplashProvider] Result: authenticated=${status.isAuthenticated}');

      final stage = status.isAuthenticated
          ? SplashStage.authenticated
          : SplashStage.unauthenticated;

      state = state.copyWith(stage: stage);
      return stage;
    } catch (e) {
      debugPrint('[SplashProvider] ERROR: $e');
      state = state.copyWith(
        stage: SplashStage.unauthenticated,
        error: e.toString(),
      );
      return SplashStage.unauthenticated;
    }
  }
}

final splashProvider = NotifierProvider<SplashNotifier, SplashState>(
  SplashNotifier.new,
);
