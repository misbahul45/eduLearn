import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;
  final Dio dio;
  bool _isRefreshing = false;

  AuthInterceptor({required this.storage, required this.dio});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isAuthEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/refresh');

    if (!isAuthEndpoint) {
      final token = await storage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');

    if (!isUnauthorized || isRefreshCall || _isRefreshing) {
      return handler.next(err);
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      return handler.next(err);
    }

    final token = await storage.read(key: 'access_token');
    final opts = err.requestOptions;
    opts.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await dio.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await storage.write(
          key: 'access_token',
          value: data['access_token'] as String,
        );
        if (data.containsKey('refresh_token')) {
          await storage.write(
            key: 'refresh_token',
            value: data['refresh_token'] as String,
          );
        }
        return true;
      }
    } catch (_) {
    } finally {
      _isRefreshing = false;
    }
    return false;
  }
}