class ClassScore {
  final String label;
  final double score;

  const ClassScore({required this.label, required this.score});

  factory ClassScore.fromJson(Map<String, dynamic> json) {
    return ClassScore(
      label: json['label'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'score': score,
      };
}

class Prediction {
  final int id;
  final String predictedLabel;
  final double confidence;
  final List<ClassScore> classScores;
  final String modelName;
  final String modelVersion;
  final DateTime generatedAt;

  const Prediction({
    required this.id,
    required this.predictedLabel,
    required this.confidence,
    required this.classScores,
    required this.modelName,
    required this.modelVersion,
    required this.generatedAt,
  });

  bool get isPassed => predictedLabel == 'Lulus';

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] as int? ?? 0,
      predictedLabel: json['predicted_label'] as String? ?? '-',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      classScores: (json['class_scores'] as List<dynamic>?)
              ?.map((e) => ClassScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelName: json['model_name'] as String? ?? '',
      modelVersion: json['model_version'] as String? ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'predicted_label': predictedLabel,
        'confidence': confidence,
        'class_scores': classScores.map((e) => e.toJson()).toList(),
        'model_name': modelName,
        'model_version': modelVersion,
        'generated_at': generatedAt.toIso8601String(),
      };
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

  Map<String, dynamic> toJson() => {
        'total_predictions': totalPredictions,
        'passed_count': passedCount,
        'failed_count': failedCount,
        'pass_rate': passRate,
        'avg_probability': avgProbability,
      };
}
