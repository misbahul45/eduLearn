/// Reflection data dari Reflector node — hasil self-evaluation sebelum respond.
class ReflectionData {
  final bool infoSufficient;
  final bool planCompleted;
  final List<String> missingAspects;
  final String nextAction; // iterate | respond
  final String reason;
  final double qualityScore; // 0.0 - 1.0

  const ReflectionData({
    required this.infoSufficient,
    required this.planCompleted,
    required this.missingAspects,
    required this.nextAction,
    required this.reason,
    required this.qualityScore,
  });

  factory ReflectionData.fromJson(Map<String, dynamic> json) {
    return ReflectionData(
      infoSufficient: json['info_sufficient'] as bool? ?? false,
      planCompleted: json['plan_completed'] as bool? ?? false,
      missingAspects: (json['missing_aspects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      nextAction: json['next_action'] as String? ?? 'respond',
      reason: json['reason'] as String? ?? '',
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'info_sufficient': infoSufficient,
        'plan_completed': planCompleted,
        'missing_aspects': missingAspects,
        'next_action': nextAction,
        'reason': reason,
        'quality_score': qualityScore,
      };

  /// Apakah perlu iterasi lagi?
  bool get needsIteration => nextAction == 'iterate';

  /// Quality score dalam format persen.
  String get qualityPercent => '${(qualityScore * 100).toInt()}%';

  /// Color label berdasarkan quality score.
  String get qualityLabel {
    if (qualityScore >= 0.8) return 'Sangat Baik';
    if (qualityScore >= 0.6) return 'Baik';
    if (qualityScore >= 0.4) return 'Cukup';
    return 'Kurang';
  }
}