import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/users_service.dart';
import 'auth_providers.dart';

final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref.watch(apiClientProvider));
});

final userMeProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(usersServiceProvider).getMe();
});

final userStatsProvider = FutureProvider.autoDispose<UserStats?>((ref) {
  return ref.watch(usersServiceProvider).getStats();
});
