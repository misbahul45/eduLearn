import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/dio_client.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient({required FlutterSecureStorage storage}) {
    _dio = buildDio(storage: storage);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> postMultipart(
    String path, {
    required FormData formData,
  }) =>
      _dio.post(path, data: formData);
}
