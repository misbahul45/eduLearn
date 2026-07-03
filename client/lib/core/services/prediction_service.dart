import 'package:dio/dio.dart';
import '../models/prediction.dart';
import 'api_client.dart';

class PredictionService {
  final ApiClient _api;

  PredictionService(this._api);

  Future<Prediction?> getLatest() async {
    try {
      final response = await _api.get('/predictions/latest');
      if (response.statusCode == 200) {
        return Prediction.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Prediction>> getHistory({int days = 30}) async {
    try {
      final response = await _api.get('/predictions/history', queryParameters: {'days': days});
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final list = data['predictions'] as List<dynamic>? ?? [];
        return list.map((e) => Prediction.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<PredictionAnalysis?> getAnalysis() async {
    try {
      final response = await _api.get('/predictions/analysis');
      if (response.statusCode == 200) {
        return PredictionAnalysis.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
