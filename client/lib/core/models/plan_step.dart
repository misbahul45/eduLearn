/// Plan Step model — satu langkah dalam execution plan dari Planner node.
class PlanStep {
  final int stepId;
  final String description;
  final String tool; // rag_tool | predictive_tool | firecrawl_tool | respond
  final Map<String, dynamic> argsHint;
  final List<int> dependsOn;
  final String status; // pending | running | done | skipped | failed
  final String resultSummary;

  const PlanStep({
    required this.stepId,
    required this.description,
    required this.tool,
    this.argsHint = const {},
    this.dependsOn = const [],
    this.status = 'pending',
    this.resultSummary = '',
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) {
    return PlanStep(
      stepId: json['step_id'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      argsHint: (json['args_hint'] as Map<String, dynamic>?) ?? {},
      dependsOn: (json['depends_on'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      resultSummary: json['result_summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'step_id': stepId,
        'description': description,
        'tool': tool,
        'args_hint': argsHint,
        'depends_on': dependsOn,
        'status': status,
        'result_summary': resultSummary,
      };

  /// Cek apakah step ini bisa dieksekusi parallel (tidak ada dependency).
  bool get isParallelEligible => dependsOn.isEmpty && tool != 'respond';

  /// Icon untuk status step.
  String get statusIcon => switch (status) {
        'pending' => '⏳',
        'running' => '🔄',
        'done' => '✅',
        'skipped' => '⏭️',
        'failed' => '❌',
        _ => '❓',
      };

  /// Icon untuk tool.
  String get toolIcon => switch (tool) {
        'rag_tool' => '📚',
        'predictive_tool' => '🎯',
        'firecrawl_tool' => '🌐',
        'respond' => '✍️',
        _ => '🔧',
      };

  /// Warna accent berdasarkan status.
  String get statusColor => switch (status) {
        'pending' => 'grey',
        'running' => 'blue',
        'done' => 'green',
        'skipped' => 'grey',
        'failed' => 'red',
        _ => 'grey',
      };

  PlanStep copyWith({
    int? stepId,
    String? description,
    String? tool,
    Map<String, dynamic>? argsHint,
    List<int>? dependsOn,
    String? status,
    String? resultSummary,
  }) {
    return PlanStep(
      stepId: stepId ?? this.stepId,
      description: description ?? this.description,
      tool: tool ?? this.tool,
      argsHint: argsHint ?? this.argsHint,
      dependsOn: dependsOn ?? this.dependsOn,
      status: status ?? this.status,
      resultSummary: resultSummary ?? this.resultSummary,
    );
  }
}