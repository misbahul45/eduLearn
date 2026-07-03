import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prediction.dart';
import '../services/prediction_service.dart';
import 'auth_providers.dart';

final predictionServiceProvider = Provider<PredictionService>((ref) {
  return PredictionService(ref.watch(apiClientProvider));
});

final latestPredictionProvider = FutureProvider.autoDispose<Prediction?>((ref) {
  return ref.watch(predictionServiceProvider).getLatest();
});

final predictionHistoryProvider = FutureProvider.autoDispose<List<Prediction>>((ref) {
  return ref.watch(predictionServiceProvider).getHistory();
});

final predictionAnalysisProvider = FutureProvider.autoDispose<PredictionAnalysis?>((ref) {
  return ref.watch(predictionServiceProvider).getAnalysis();
});
