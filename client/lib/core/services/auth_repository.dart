import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_status.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthRepository({
    required this._api,
    required FlutterSecureStorage storage,
  })  : _storage = storage;

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

  String _mapError(DioException e) {
    if (e.error is SocketException || e.type == DioExceptionType.connectionError) {
      return 'Tidak ada koneksi internet';
    }
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return 'Email atau password salah';
    }
    if (statusCode == 409) {
      return 'Email sudah terdaftar';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Server sedang bermasalah, coba lagi';
    }
    final detail = e.response?.data is Map
        ? (e.response!.data as Map)['detail'] as String?
        : null;
    return detail ?? 'Terjadi kesalahan, coba lagi';
  }

  Future<AuthStatus> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
      );
      final me = await _api.get('/auth/me');
      if (me.statusCode == 200) {
        final user = User.fromJson(me.data as Map<String, dynamic>);
        return AuthStatus(result: AuthResult.authenticated, user: user);
      }
    } on DioException catch (e) {
      throw Exception(_mapError(e));
    }
    throw Exception('Terjadi kesalahan, coba lagi');
  }

  Future<AuthStatus> register(String name, String email, String password) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      await saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
      );
      final me = await _api.get('/auth/me');
      if (me.statusCode == 200) {
        final user = User.fromJson(me.data as Map<String, dynamic>);
        return AuthStatus(result: AuthResult.authenticated, user: user);
      }
    } on DioException catch (e) {
      throw Exception(_mapError(e));
    }
    throw Exception('Terjadi kesalahan, coba lagi');
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await clearTokens();
  }
}
