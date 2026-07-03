import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/agent_event.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/agent_socket_service.dart';
import '../../../core/services/chat_repository.dart';
import 'chat_state.dart';

class ChatViewModel extends Notifier<ChatState> {
  late final AgentSocketService _socketService;
  late final ChatRepository _chatRepository;
  StreamSubscription<AgentEvent>? _eventSub;

  @override
  ChatState build() {
    final storage = ref.watch(secureStorageProvider);
    final api = ref.watch(apiClientProvider);

    _socketService = AgentSocketService(storage: storage);
    _chatRepository = ChatRepository(api);

    _socketService.connect();
    _socketService.listenForeground();
    _eventSub = _socketService.events?.listen(_onEvent);

    ref.onDispose(() {
      _eventSub?.cancel();
      _socketService.dispose();
    });

    return const ChatState();
  }

  void _onEvent(AgentEvent event) {
    final trace = [...state.traceLog, event];

    switch (event) {
      case StateUpdateEvent e:
        final isActive = const {
          'supervisor',
          'rag_tool',
          'firecrawl_tool',
          'predictive_tool',
          'response_node',
        }.contains(e.node);
        state = state.copyWith(
          traceLog: trace,
          status: isActive ? AgentStatus.thinking : AgentStatus.online,
        );

      case ToolCallEvent _:
        state = state.copyWith(traceLog: trace);

      case ToolResultEvent _:
        state = state.copyWith(traceLog: trace);

      case TokenEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              content: msg.content + e.content,
            ),
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
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              citations: [
                ...msg.citations,
                Citation(e.sourceId, e.snippet, e.score, e.metadata),
              ],
            ),
          );
        }

      case WebSearchResultEvent e:
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              webResults: [
                ...msg.webResults,
                WebSearchResult(
                  resultId: e.resultId,
                  url: e.url,
                  title: e.title,
                  snippet: e.snippet,
                  markdownExcerpt: e.markdownExcerpt,
                  source: e.source,
                  relevanceScore: e.relevanceScore,
                ),
              ],
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
            clearStreaming: true,
            status: AgentStatus.online,
            isSending: false,
            conversationId: e.conversationId.isNotEmpty
                ? e.conversationId
                : state.conversationId,
          );
        }

      case AgentErrorEvent e:
        if (e.fatal) {
          state = state.copyWith(
            status: AgentStatus.online,
            isSending: false,
          );
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

    final now = DateTime.now();
    final userMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      isUser: true,
      content: text.trim(),
      timestamp: now,
    );
    final assistantMsg = ChatMessage(
      id: 'stream_${now.millisecondsSinceEpoch}',
      isUser: false,
      isStreaming: true,
      timestamp: now,
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
      final response = await _chatRepository.sendMessage(
        text,
        conversationId: state.conversationId,
      );
      final msg = state.currentStreamingMessage;
      if (msg != null) {
        final finalMsg = msg.copyWith(
          content: response['message'] as String? ?? '',
          isStreaming: false,
        );
        if (response['conversation_id'] != null) {
          state = state.copyWith(
            conversationId: response['conversation_id'] as String,
          );
        }
        state = state.copyWith(
          messages: [...state.messages, finalMsg],
          clearStreaming: true,
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

  Future<void> reconnectWs() async {
    await _socketService.reconnect();
    state = state.copyWith(connectionMode: _socketService.mode);
  }

  void clearHistory() {
    state = const ChatState();
  }
}

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(ChatViewModel.new);

final chatPresetQueryProvider = StateProvider<String?>((ref) => null);
