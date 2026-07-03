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

class SplashNotifier extends AsyncNotifier<SplashState> {
  @override
  SplashState build() => const SplashState();

  Future<SplashStage> check() async {
    state = state.copyWith(stage: SplashStage.checking);

    final repository = ref.read(authRepositoryProvider);
    final status = await repository.checkAuth();

    final stage = status.isAuthenticated
        ? SplashStage.authenticated
        : SplashStage.unauthenticated;

    state = state.copyWith(stage: stage);
    return stage;
  }
}

final splashProvider = AsyncNotifierProvider<SplashNotifier, SplashState>(
  SplashNotifier.new,
);
