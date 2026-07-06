import '../models/agent_event.dart';

class WsEventParser {
  WsEventParser._();

  static AgentEvent? parse(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final ts = DateTime.now();

    try {
      return switch (type) {
        'connection' => ConnectionEvent(
            json['status'] as String? ?? 'connected',
            ts,
          ),
        'state_update' => StateUpdateEvent(
            json['node'] as String? ?? '',
            json['status'] as String? ?? '',
            (json['iteration'] as num?)?.toInt() ?? 0,
            reasoningPreview: json['reasoning_preview'] as String?,
            toolCallsCount: (json['tool_calls_count'] as num?)?.toInt(),
            timestamp: ts,
          ),
        'plan_generated' => PlanGeneratedEvent(
            (json['steps'] as List<dynamic>?)
                    ?.map((e) =>
                        PlanStep.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [],
            json['reasoning'] as String? ?? '',
            json['needs_planning'] as bool? ?? true,
            ts,
          ),
        'reflection' => ReflectionEvent(
            json['info_sufficient'] != null ||
                    json['next_action'] != null ||
                    json['quality_score'] != null
                ? ReflectionData(
                    infoSufficient:
                        json['info_sufficient'] as bool? ?? false,
                    planCompleted:
                        json['plan_completed'] as bool? ?? false,
                    missingAspects:
                        (json['missing_aspects'] as List<dynamic>?)
                                ?.map((e) => e as String)
                                .toList() ??
                            [],
                    nextAction:
                        json['next_action'] as String? ?? 'respond',
                    reason: json['reason'] as String? ?? '',
                    qualityScore:
                        (json['quality_score'] as num?)?.toDouble() ??
                            0.0,
                  )
                : ReflectionData(
                    infoSufficient: false,
                    planCompleted: false,
                    missingAspects: const [],
                    nextAction: 'respond',
                    reason: '',
                    qualityScore: 0.0,
                  ),
            ts,
          ),
        'tool_call' => ToolCallEvent(
            json['tool_name'] as String? ?? '',
            json['input'] as Map<String, dynamic>? ?? {},
            json['call_id'] as String? ?? '',
            parallelGroup: json['parallel_group'] as String?,
            iteration: (json['iteration'] as num?)?.toInt() ?? 0,
            timestamp: ts,
          ),
        'tool_result' => ToolResultEvent(
            json['tool_name'] as String? ?? '',
            json['call_id'] as String? ?? '',
            json['output_summary'] as String? ?? '',
            (json['duration_ms'] as num?)?.toInt() ?? 0,
            parallelGroup: json['parallel_group'] as String?,
            success: json['success'] as bool? ?? true,
            iteration: (json['iteration'] as num?)?.toInt() ?? 0,
            timestamp: ts,
          ),
        'token' => TokenEvent(
            json['content'] as String? ?? '',
            (json['index'] as num?)?.toInt() ?? 0,
            ts,
          ),
        'citation' => CitationEvent(
            json['source_id'] as String? ?? '',
            json['snippet'] as String? ?? '',
            (json['score'] as num?)?.toDouble() ?? 0.0,
            json['metadata'] != null
                ? CitationMeta.fromJson(
                    json['metadata'] as Map<String, dynamic>)
                : const CitationMeta(),
            ts,
          ),
        'web_search_result' => WebSearchResultEvent(
            json['result_id'] as String? ?? '',
            json['url'] as String? ?? '',
            json['title'] as String? ?? '',
            json['snippet'] as String? ?? '',
            json['markdown_excerpt'] as String? ?? '',
            json['source'] as String? ?? 'firecrawl',
            (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
            ts,
          ),
        'prediction_result' => PredictionResultEvent(
            json['data'] != null
                ? PredictionResult.fromJson(
                    json['data'] as Map<String, dynamic>)
                : PredictionResult(
                    predictedLabel: '',
                    confidence: 0,
                    classScores: const [],
                    modelName: '',
                    modelVersion: '',
                    inputFeaturesUsed: const [],
                    generatedAt: ts,
                  ),
            ts,
          ),
        'final' => FinalEvent(
            json['message'] as String? ?? '',
            json['conversation_id'] as String? ?? '',
            (json['citations'] as List<dynamic>?)?.cast<String>() ?? [],
            (json['web_results'] as List<dynamic>?)?.cast<String>() ?? [],
            json['prediction_present'] as bool? ?? false,
            json['prediction_label'] as String?,
            ts,
          ),
        'error' => AgentErrorEvent(
            json['node'] as String?,
            json['message'] as String? ?? '',
            json['fatal'] as bool? ?? false,
            ts,
          ),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }
}