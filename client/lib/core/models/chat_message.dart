import 'agent_event.dart';

class ChatMessage {
  final String id;
  final bool isUser;
  final String content;
  final bool isStreaming;
  final List<Citation> citations;
  final List<WebSearchResult> webResults;
  final PredictionResult? prediction;
  final DateTime timestamp;
  final String? error;

  const ChatMessage({
    required this.id,
    required this.isUser,
    this.content = '',
    this.isStreaming = false,
    this.citations = const [],
    this.webResults = const [],
    this.prediction,
    required this.timestamp,
    this.error,
  });

  ChatMessage copyWith({
    String? id,
    bool? isUser,
    String? content,
    bool? isStreaming,
    List<Citation>? citations,
    List<WebSearchResult>? webResults,
    PredictionResult? prediction,
    DateTime? timestamp,
    String? error,
    bool clearError = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      isUser: isUser ?? this.isUser,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      citations: citations ?? this.citations,
      webResults: webResults ?? this.webResults,
      prediction: prediction ?? this.prediction,
      timestamp: timestamp ?? this.timestamp,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
