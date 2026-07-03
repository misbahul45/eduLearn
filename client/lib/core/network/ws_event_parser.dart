import '../models/agent_event.dart';

class WsEventParser {
  WsEventParser._();

  static AgentEvent? parse(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final ts = DateTime.now();

    try {
      return switch (type) {
        'state_update' => StateUpdateEvent(
            json['node'] as String? ?? '',
            json['status'] as String? ?? '',
            (json['iteration'] as num?)?.toInt() ?? 0,
            ts,
          ),
        'tool_call' => ToolCallEvent(
            json['tool_name'] as String? ?? '',
            json['input'] as Map<String, dynamic>? ?? {},
            json['call_id'] as String? ?? '',
            ts,
          ),
        'tool_result' => ToolResultEvent(
            json['tool_name'] as String? ?? '',
            json['call_id'] as String? ?? '',
            json['output_summary'] as String? ?? '',
            (json['duration_ms'] as num?)?.toInt() ?? 0,
            ts,
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
