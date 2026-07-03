class Prediction {
  final String id;
  final String label;
  final double probability;
  final DateTime createdAt;

  const Prediction({
    required this.id,
    required this.label,
    required this.probability,
    required this.createdAt,
  });

  bool get isPassed => label == 'Lulus';

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '-',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class PredictionAnalysis {
  final int totalPredictions;
  final int passedCount;
  final int failedCount;
  final double passRate;
  final double avgProbability;

  const PredictionAnalysis({
    required this.totalPredictions,
    required this.passedCount,
    required this.failedCount,
    required this.passRate,
    required this.avgProbability,
  });

  factory PredictionAnalysis.fromJson(Map<String, dynamic> json) {
    return PredictionAnalysis(
      totalPredictions: json['total_predictions'] as int? ?? 0,
      passedCount: json['passed_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
      passRate: (json['pass_rate'] as num?)?.toDouble() ?? 0.0,
      avgProbability: (json['avg_probability'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
