import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/agent_event.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/agent_socket_service.dart';
import '../../../core/services/chat_repository.dart';

enum AgentStatus { idle, thinking, online }

class ChatState {
  final List<ChatMessage> messages;
  final ChatMessage? currentStreamingMessage;
  final List<AgentEvent> traceLog;
  final AgentStatus status;
  final ConnectionMode connectionMode;
  final bool isSending;

  const ChatState({
    this.messages = const [],
    this.currentStreamingMessage,
    this.traceLog = const [],
    this.status = AgentStatus.online,
    this.connectionMode = ConnectionMode.realtime,
    this.isSending = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatMessage? currentStreamingMessage,
    List<AgentEvent>? traceLog,
    AgentStatus? status,
    ConnectionMode? connectionMode,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      currentStreamingMessage: currentStreamingMessage ?? this.currentStreamingMessage,
      traceLog: traceLog ?? this.traceLog,
      status: status ?? this.status,
      connectionMode: connectionMode ?? this.connectionMode,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatViewModel extends StateNotifier<ChatState> {
  final AgentSocketService _socketService;
  final ChatRepository _chatRepository;
  final Ref _ref;

  ChatViewModel(this._socketService, this._chatRepository, this._ref)
      : super(const ChatState()) {
    _init();
    _ref.onDispose(() {
      _socketService.dispose();
    });
  }

  void _init() {
    _socketService.connect();
    _socketService.events?.listen(_onEvent);
  }

  void _onEvent(AgentEvent event) {
    final trace = [...state.traceLog, event];

    switch (event) {
      case StateUpdateEvent e:
        final status = switch (e.node) {
          'supervisor' || 'rag_tool' || 'firecrawl_tool' || 'predictive_tool' || 'response_node' =>
            AgentStatus.thinking,
          _ => AgentStatus.online,
        };
        state = state.copyWith(traceLog: trace, status: status);

      case ToolCallEvent _:
        state = state.copyWith(traceLog: trace);

      case ToolResultEvent _:
        state = state.copyWith(traceLog: trace);

      case TokenEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(content: msg.content + e.content),
          );
        }

      case PredictionResultEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(prediction: e.data),
          );
        }

      case CitationEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          final citation = Citation(e.sourceId, e.snippet, e.score, e.metadata);
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              citations: [...msg.citations, citation],
            ),
          );
        }

      case WebSearchResultEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          final result = WebSearchResult(
            resultId: e.resultId,
            url: e.url,
            title: e.title,
            snippet: e.snippet,
            markdownExcerpt: e.markdownExcerpt,
            source: e.source,
            relevanceScore: e.relevanceScore,
          );
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              webResults: [...msg.webResults, result],
            ),
          );
        }

      case FinalEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          final finalMsg = msg.copyWith(
            content: e.message.isNotEmpty ? e.message : msg.content,
            isStreaming: false,
          );
          state = state.copyWith(
            messages: [...state.messages, finalMsg],
            currentStreamingMessage: null,
            status: AgentStatus.online,
            isSending: false,
          );
        }

      case AgentErrorEvent e:
        if (e.fatal) {
          state = state.copyWith(status: AgentStatus.online, isSending: false);
        } else {
          final msg = state.currentStreamingMessage;
          if (msg != null) {
            state = state.copyWith(
              currentStreamingMessage: msg.copyWith(error: e.message),
            );
          }
        }

    }
  }

  void sendMessage(String text) {
    if (state.isSending || text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isUser: true,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    final assistantMsg = ChatMessage(
      id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      isStreaming: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      currentStreamingMessage: assistantMsg,
      isSending: true,
      status: AgentStatus.thinking,
    );

    if (state.connectionMode == ConnectionMode.realtime) {
      _socketService.sendMessage(text);
    } else {
      _sendRestFallback(text);
    }
  }

  Future<void> _sendRestFallback(String text) async {
    try {
      final response = await _chatRepository.sendMessage(text);
      final msg = state.currentStreamingMessage;
      if (msg != null) {
        final finalMsg = msg.copyWith(
          content: response['message'] as String? ?? '',
          isStreaming: false,
        );
        state = state.copyWith(
          messages: [...state.messages, finalMsg],
          currentStreamingMessage: null,
          isSending: false,
        );
      }
    } catch (e) {
      final msg = state.currentStreamingMessage;
      if (msg != null) {
        state = state.copyWith(
          currentStreamingMessage: msg.copyWith(
            error: e.toString().replaceFirst('Exception: ', ''),
            isStreaming: false,
          ),
          isSending: false,
        );
      }
    }
  }

  void reconnectWs() async {
    await _socketService.reconnect();
    state = state.copyWith(connectionMode: _socketService.mode);
  }

  void clearHistory() {
    state = const ChatState();
  }
}

final chatViewModelProvider =
    StateNotifierProvider<ChatViewModel, ChatState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final api = ref.watch(apiClientProvider);
  final socketService = AgentSocketService(storage: storage);
  final chatRepository = ChatRepository(api);
  return ChatViewModel(socketService, chatRepository, ref);
});

final chatPresetQueryProvider = StateProvider<String?>((ref) => null);
