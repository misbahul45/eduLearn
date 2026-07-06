/// Enhanced ChatMessage model — mendukung plan + reflection untuk multi-step ReAct.
library;
import 'agent_event.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final bool isStreaming;
  final DateTime timestamp;

  // Tool results
  final PredictionResult? prediction;
  final List<Citation> citations;
  final List<WebSearchResult> webResults;
  final String? error;


  final List<PlanStep>? planSteps;
  final ReflectionData? reflection;


  final List<ParallelToolGroup>? parallelGroups;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    DateTime? timestamp,
    this.prediction,
    this.citations = const [],
    this.webResults = const [],
    this.error,
    this.planSteps,
    this.reflection,
    this.parallelGroups,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Factory untuk pesan user.
  factory ChatMessage.user({
    required String id,
    required String content,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      isUser: true,
      isStreaming: false,
    );
  }

  /// Factory untuk pesan AI (streaming).
  factory ChatMessage.ai({
    required String id,
    String content = '',
    bool isStreaming = true,
  }) {
    return ChatMessage(
      id: id,
      content: content,
      isUser: false,
      isStreaming: isStreaming,
    );
  }

  /// Copy with helpers untuk streaming updates.
  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    PredictionResult? prediction,
    List<Citation>? citations,
    List<WebSearchResult>? webResults,
    String? error,
    List<PlanStep>? planSteps,
    ReflectionData? reflection,
    List<ParallelToolGroup>? parallelGroups,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp,
      prediction: prediction ?? this.prediction,
      citations: citations ?? this.citations,
      webResults: webResults ?? this.webResults,
      error: error ?? this.error,
      planSteps: planSteps ?? this.planSteps,
      reflection: reflection ?? this.reflection,
      parallelGroups: parallelGroups ?? this.parallelGroups,
    );
  }

  /// Cek apakah pesan punya rich content (prediction/citations/web/plan/reflection).
  bool get hasRichContent =>
      prediction != null ||
      citations.isNotEmpty ||
      webResults.isNotEmpty ||
      (planSteps != null && planSteps!.isNotEmpty) ||
      reflection != null;
}

/// Group of tool calls yang dieksekusi secara parallel.
class ParallelToolGroup {
  final String groupId; // "iter_2_n3"
  final int iteration;
  final List<ParallelToolEntry> entries;
  final int totalDurationMs;

  const ParallelToolGroup({
    required this.groupId,
    required this.iteration,
    required this.entries,
    required this.totalDurationMs,
  });

  bool get allSuccess => entries.every((e) => e.success);
  int get successCount => entries.where((e) => e.success).length;
  int get failureCount => entries.where((e) => !e.success).length;
}

/// Single tool entry dalam parallel group.
class ParallelToolEntry {
  final String toolName;
  final String callId;
  final String summary;
  final int durationMs;
  final bool success;

  const ParallelToolEntry({
    required this.toolName,
    required this.callId,
    required this.summary,
    required this.durationMs,
    required this.success,
  });

  String get toolIcon => switch (toolName) {
        'rag_tool' => '📚',
        'predictive_tool' => '🎯',
        'firecrawl_tool' => '🌐',
        _ => '🔧',
      };
}