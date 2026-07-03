import '../../../core/models/agent_event.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/agent_socket_service.dart';

enum AgentStatus { idle, thinking, online }

class ChatState {
  final List<ChatMessage> messages;
  final ChatMessage? currentStreamingMessage;
  final List<AgentEvent> traceLog;
  final AgentStatus status;
  final ConnectionMode connectionMode;
  final bool isSending;
  final String? conversationId;

  const ChatState({
    this.messages = const [],
    this.currentStreamingMessage,
    this.traceLog = const [],
    this.status = AgentStatus.online,
    this.connectionMode = ConnectionMode.realtime,
    this.isSending = false,
    this.conversationId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatMessage? currentStreamingMessage,
    bool clearStreaming = false,
    List<AgentEvent>? traceLog,
    AgentStatus? status,
    ConnectionMode? connectionMode,
    bool? isSending,
    String? conversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      currentStreamingMessage: clearStreaming
          ? null
          : currentStreamingMessage ?? this.currentStreamingMessage,
      traceLog: traceLog ?? this.traceLog,
      status: status ?? this.status,
      connectionMode: connectionMode ?? this.connectionMode,
      isSending: isSending ?? this.isSending,
      conversationId: conversationId ?? this.conversationId,
    );
  }
}
