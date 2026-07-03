import 'user.dart';

enum AuthResult { authenticated, unauthenticated }

class AuthStatus {
  final AuthResult result;
  final User? user;

  const AuthStatus({required this.result, this.user});

  bool get isAuthenticated => result == AuthResult.authenticated;
}
