
import '../models/user.dart';
import 'api_client.dart';

class UsersService {
  final ApiClient _api;

  UsersService(this._api);

  Future<User?> getMe() async {
    try {
      final response = await _api.get('/users/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<UserStats?> getStats() async {
    try {
      final response = await _api.get('/users/stats');
      if (response.statusCode == 200) {
        return UserStats.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
