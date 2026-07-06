/// Enhanced Agent Event Model — mendukung multi-step ReAct workflow.
///
/// Perubahan dari versi lama:
/// 1. Tambah `PlanGeneratedEvent` untuk plan dari Planner node
/// 2. Tambah `ReflectionEvent` untuk feedback dari Reflector node
/// 3. `ToolCallEvent` & `ToolResultEvent` dapat `parallelGroup` field
/// 4. Setiap event punya `icon` (emoji) dan `phase` (planner/supervisor/tools/reflector/respond)
/// 5. `StateUpdateEvent` dapat `reasoningPreview` dan `toolCallsCount`
library;

import 'plan_step.dart';
import 'reflection_data.dart';

export 'plan_step.dart';
export 'reflection_data.dart';

// ============================================================
// Base sealed class
// ============================================================

sealed class AgentEvent {
  final DateTime timestamp;

  const AgentEvent(this.timestamp);

  String get summary;
  String get detail;

  /// Emoji icon untuk visual di trace sheet.
  String get icon;

  /// Phase: planner | supervisor | tools | reflector | respond | system
  String get phase;
}

// ============================================================
// System / Connection events
// ============================================================

class ConnectionEvent extends AgentEvent {
  final String status; // connected | disconnected | reconnecting | rest_mode

  const ConnectionEvent(this.status, super.timestamp);

  @override
  String get summary => 'Connection: $status';

  @override
  String get detail => '';

  @override
  String get icon => '🔌';

  @override
  String get phase => 'system';
}

// ============================================================
// State Update (dari semua node)
// ============================================================

class StateUpdateEvent extends AgentEvent {
  final String node; // planner | supervisor | tools | reflector | respond
  final String status; // started | completed
  final int iteration;
  final String? reasoningPreview;
  final int? toolCallsCount;

  const StateUpdateEvent(
    this.node,
    this.status,
    this.iteration, {
    this.reasoningPreview,
    this.toolCallsCount,
    required DateTime timestamp,
  }) : super(timestamp);

  @override
  String get summary => '[$node] $status';

  @override
  String get detail {
    final parts = <String>['Iterasi $iteration'];
    if (toolCallsCount != null && toolCallsCount! > 0) {
      parts.add('$toolCallsCount tool calls');
    }
    if (reasoningPreview != null && reasoningPreview!.isNotEmpty) {
      parts.add(reasoningPreview!.substring(0, reasoningPreview!.length.clamp(0, 80)));
    }
    return parts.join(' · ');
  }

  @override
  String get icon => _nodeIcon(node);

  @override
  String get phase => node;

  static String _nodeIcon(String node) => switch (node) {
        'planner' => '🗺️',
        'supervisor' => '🧠',
        'tools' => '🔧',
        'reflector' => '🔍',
        'respond' => '✍️',
        _ => '•',
      };
}

// ============================================================
// Plan Generated (BARU — dari Planner node)
// ============================================================

class PlanGeneratedEvent extends AgentEvent {
  final List<PlanStep> steps;
  final String reasoning;
  final bool needsPlanning;

  const PlanGeneratedEvent(
    this.steps,
    this.reasoning,
    this.needsPlanning,
    super.timestamp,
  );

  @override
  String get summary =>
      needsPlanning ? 'Plan: ${steps.length} steps' : 'Simple query (skip plan)';

  @override
  String get detail {
    if (!needsPlanning) return 'Single-intent query';
    final parallel = steps.where((s) => s.dependsOn.isEmpty && s.tool != 'respond').length;
    return '${steps.length} steps · ${parallel > 1 ? "$parallel parallel" : "sequential"}';
  }

  @override
  String get icon => '🗺️';

  @override
  String get phase => 'planner';
}

// ============================================================
// Tool Call (enhanced dengan parallelGroup)
// ============================================================

class ToolCallEvent extends AgentEvent {
  final String toolName;
  final Map<String, dynamic> input;
  final String callId;
  final String? parallelGroup; // "iter_2_n3" jika parallel
  final int iteration;

  const ToolCallEvent(
    this.toolName,
    this.input,
    this.callId, {
    this.parallelGroup,
    this.iteration = 0,
    required DateTime timestamp,
  }) : super(timestamp);

  bool get isParallel => parallelGroup != null;

  @override
  String get summary => '→ $toolName${isParallel ? ' (parallel)' : ''}';

  @override
  String get detail {
    final inputPreview = input.entries.take(3).map((e) {
      final val = e.value.toString();
      return '${e.key}: ${val.substring(0, val.length.clamp(0, 40))}';
    }).join(', ');
    return 'Args: $inputPreview';
  }

  @override
  String get icon => _toolIcon(toolName);

  @override
  String get phase => 'tools';

  static String _toolIcon(String tool) => switch (tool) {
        'rag_tool' => '📚',
        'predictive_tool' => '🎯',
        'firecrawl_tool' => '🌐',
        _ => '🔧',
      };
}

// ============================================================
// Tool Result (enhanced dengan parallelGroup + success)
// ============================================================

class ToolResultEvent extends AgentEvent {
  final String toolName;
  final String callId;
  final String outputSummary;
  final int durationMs;
  final String? parallelGroup;
  final bool success;
  final int iteration;

  const ToolResultEvent(
    this.toolName,
    this.callId,
    this.outputSummary,
    this.durationMs, {
    this.parallelGroup,
    this.success = true,
    this.iteration = 0,
    required DateTime timestamp,
  }) : super(timestamp);

  bool get isParallel => parallelGroup != null;

  @override
  String get summary => '${success ? "✓" : "✗"} $toolName';

  @override
  String get detail => '${durationMs}ms · $outputSummary';

  @override
  String get icon => success ? '✅' : '❌';

  @override
  String get phase => 'tools';
}

// ============================================================
// Reflection (BARU — dari Reflector node)
// ============================================================

class ReflectionEvent extends AgentEvent {
  final ReflectionData data;

  const ReflectionEvent(this.data, super.timestamp);

  @override
  String get summary =>
      'Reflection: ${data.nextAction} (quality: ${(data.qualityScore * 100).toInt()}%)';

  @override
  String get detail {
    final parts = <String>[data.reason];
    if (data.missingAspects.isNotEmpty) {
      parts.add('Missing: ${data.missingAspects.join(", ")}');
    }
    return parts.join(' · ');
  }

  @override
  String get icon => '🔍';

  @override
  String get phase => 'reflector';
}

// ============================================================
// Streaming Token
// ============================================================

class TokenEvent extends AgentEvent {
  final String content;
  final int index;

  const TokenEvent(this.content, this.index, super.timestamp);

  @override
  String get summary => 'Token #${index + 1}';

  @override
  String get detail => content.substring(0, content.length.clamp(0, 50));

  @override
  String get icon => '💬';

  @override
  String get phase => 'respond';
}

// ============================================================
// Prediction Result
// ============================================================

class PredictionResultEvent extends AgentEvent {
  final PredictionResult data;

  const PredictionResultEvent(this.data, super.timestamp);

  @override
  String get summary => 'Prediksi: ${data.predictedLabel}';

  @override
  String get detail =>
      'Confidence: ${(data.confidence * 100).toStringAsFixed(1)}%';

  @override
  String get icon => '🎯';

  @override
  String get phase => 'tools';
}

// ============================================================
// Citation (RAG)
// ============================================================

class CitationEvent extends AgentEvent {
  final String sourceId;
  final String snippet;
  final double score;
  final CitationMeta metadata;

  const CitationEvent(
    this.sourceId,
    this.snippet,
    this.score,
    this.metadata,
    super.timestamp,
  );

  @override
  String get summary => '📚 Sumber: ${metadata.title ?? "Untitled"}';

  @override
  String get detail => 'Score: ${(score * 100).toStringAsFixed(0)}% · ${snippet.substring(0, snippet.length.clamp(0, 60))}...';

  @override
  String get icon => '📚';

  @override
  String get phase => 'tools';
}

// ============================================================
// Web Search Result (Firecrawl)
// ============================================================

class WebSearchResultEvent extends AgentEvent {
  final String resultId;
  final String url;
  final String title;
  final String snippet;
  final String markdownExcerpt;
  final String source;
  final double relevanceScore;

  const WebSearchResultEvent(
    this.resultId,
    this.url,
    this.title,
    this.snippet,
    this.markdownExcerpt,
    this.source,
    this.relevanceScore,
    super.timestamp,
  );

  @override
  String get summary => '🌐 $title';

  @override
  String get detail => '$source · ${(relevanceScore * 100).toStringAsFixed(0)}% match';

  @override
  String get icon => '🌐';

  @override
  String get phase => 'tools';
}

// ============================================================
// Final Response
// ============================================================

class FinalEvent extends AgentEvent {
  final String message;
  final String conversationId;
  final List<String> citations;
  final List<String> webResults;
  final bool predictionPresent;
  final String? predictionLabel;

  const FinalEvent(
    this.message,
    this.conversationId,
    this.citations,
    this.webResults,
    this.predictionPresent,
    this.predictionLabel,
    super.timestamp,
  );

  @override
  String get summary => 'Respon final diterima';

  @override
  String get detail {
    final parts = <String>[];
    if (predictionPresent) parts.add('Mengandung prediksi');
    if (citations.isNotEmpty) parts.add('${citations.length} citations');
    if (webResults.isNotEmpty) parts.add('${webResults.length} web results');
    return parts.join(' · ');
  }

  @override
  String get icon => '✅';

  @override
  String get phase => 'respond';
}

// ============================================================
// Error
// ============================================================

class AgentErrorEvent extends AgentEvent {
  final String? node;
  final String message;
  final bool fatal;

  const AgentErrorEvent(
    this.node,
    this.message,
    this.fatal,
    super.timestamp,
  );

  @override
  String get summary => '${fatal ? "❌ Fatal" : "⚠️"} Error${node != null ? " [$node]" : ""}';

  @override
  String get detail => message;

  @override
  String get icon => fatal ? '❌' : '⚠️';

  @override
  String get phase => node ?? 'system';
}

// ============================================================
// Data Models (existing, kept for compatibility)
// ============================================================

class CitationMeta {
  final String? title;
  final String? author;
  final int? page;
  final String? url;
  final String? documentId;
  final String? fileName;

  const CitationMeta({
    this.title,
    this.author,
    this.page,
    this.url,
    this.documentId,
    this.fileName,
  });

  factory CitationMeta.fromJson(Map<String, dynamic> json) {
    return CitationMeta(
      title: json['title'] as String?,
      author: json['author'] as String?,
      page: json['page'] as int?,
      url: json['url'] as String?,
      documentId: json['document_id'] as String?,
      fileName: json['file_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (title != null) 'title': title,
        if (author != null) 'author': author,
        if (page != null) 'page': page,
        if (url != null) 'url': url,
        if (documentId != null) 'document_id': documentId,
        if (fileName != null) 'file_name': fileName,
      };
}

class WebSearchResult {
  final String resultId;
  final String url;
  final String title;
  final String snippet;
  final String markdownExcerpt;
  final String source;
  final double relevanceScore;

  const WebSearchResult({
    required this.resultId,
    required this.url,
    required this.title,
    required this.snippet,
    required this.markdownExcerpt,
    required this.source,
    required this.relevanceScore,
  });

  factory WebSearchResult.fromJson(Map<String, dynamic> json) {
    return WebSearchResult(
      resultId: json['result_id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      snippet: json['snippet'] as String? ?? '',
      markdownExcerpt: json['markdown_excerpt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'result_id': resultId,
        'url': url,
        'title': title,
        'snippet': snippet,
        'markdown_excerpt': markdownExcerpt,
        'source': source,
        'relevance_score': relevanceScore,
      };
}

class Citation {
  final String sourceId;
  final String snippet;
  final double score;
  final CitationMeta metadata;

  const Citation(this.sourceId, this.snippet, this.score, this.metadata);

  factory Citation.fromJson(Map<String, dynamic> json) {
    return Citation(
      json['source_id'] as String? ?? '',
      json['snippet'] as String? ?? '',
      (json['score'] as num?)?.toDouble() ?? 0.0,
      json['metadata'] != null
          ? CitationMeta.fromJson(json['metadata'] as Map<String, dynamic>)
          : const CitationMeta(),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_id': sourceId,
        'snippet': snippet,
        'score': score,
        'metadata': metadata.toJson(),
      };
}

class PredictionResult {
  final String predictedLabel;
  final double confidence;
  final List<ClassScore> classScores;
  final String modelName;
  final String modelVersion;
  final List<String> inputFeaturesUsed;
  final DateTime generatedAt;

  const PredictionResult({
    required this.predictedLabel,
    required this.confidence,
    required this.classScores,
    required this.modelName,
    required this.modelVersion,
    required this.inputFeaturesUsed,
    required this.generatedAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictedLabel: json['predicted_label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      classScores: (json['class_scores'] as List<dynamic>?)
              ?.map((e) => ClassScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelName: json['model_name'] as String? ?? '',
      modelVersion: json['model_version'] as String? ?? '',
      inputFeaturesUsed: (json['input_features_used'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'predicted_label': predictedLabel,
        'confidence': confidence,
        'class_scores': classScores.map((e) => e.toJson()).toList(),
        'model_name': modelName,
        'model_version': modelVersion,
        'input_features_used': inputFeaturesUsed,
        'generated_at': generatedAt.toIso8601String(),
      };
}

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