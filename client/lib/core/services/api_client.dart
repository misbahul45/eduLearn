import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient({required FlutterSecureStorage storage, String? baseUrl})
      : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'https://api.edulearn.ai/api/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<void> _attachToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    await _attachToken();
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    await _attachToken();
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    await _attachToken();
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    await _attachToken();
    return _dio.delete(path);
  }
}
