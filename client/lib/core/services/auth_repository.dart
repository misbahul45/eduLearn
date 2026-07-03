import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_status.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required ApiClient api,
    required FlutterSecureStorage storage,
  })  : _api = api,
        _storage = storage;

  Future<AuthStatus> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      return const AuthStatus(result: AuthResult.unauthenticated);
    }

    try {
      final response = await _api.get('/auth/me');
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        return AuthStatus(result: AuthResult.authenticated, user: user);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          final response = await _api.get('/auth/me');
          if (response.statusCode == 200) {
            final user = User.fromJson(response.data as Map<String, dynamic>);
            return AuthStatus(result: AuthResult.authenticated, user: user);
          }
        }
      }
    } catch (_) {}

    return const AuthStatus(result: AuthResult.unauthenticated);
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _api.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await _storage.write(key: 'access_token', value: data['access_token'] as String);
        if (data.containsKey('refresh_token')) {
          await _storage.write(key: 'refresh_token', value: data['refresh_token'] as String);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}
