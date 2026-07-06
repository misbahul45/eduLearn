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
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isReconnecting = false;
  
  static const int _maxTraceLogSize = 100;
  static const int _maxReconnectAttempts = 5;
  static const int _messageTimeoutSeconds = 60;
  Timer? _messageTimeoutTimer;

  @override
  ChatState build() {
    final storage = ref.watch(secureStorageProvider);
    final api = ref.watch(apiClientProvider);

    _socketService = AgentSocketService(storage: storage);
    _chatRepository = ChatRepository(api);

    _initializeSocket();
    _socketService.listenForeground();

    ref.onDispose(() {
      _eventSub?.cancel();
      _reconnectTimer?.cancel();
      _messageTimeoutTimer?.cancel();
      _socketService.dispose();
    });

    return const ChatState();
  }

  void _initializeSocket() {
    _socketService.connect();
    _eventSub = _socketService.events?.listen(
      _onEvent,
      onError: _onStreamError,
      onDone: _onStreamDone,
      cancelOnError: false,
    );
  }

  void _onStreamError(Object error, StackTrace stack) {
    if (_socketService.isProcessing) {
      return;
    }
    state = state.copyWith(
      status: AgentStatus.online,
      connectionMode: ConnectionMode.rest,
    );
    _scheduleReconnect();
  }

  void _onStreamDone() {
    if (_socketService.isProcessing) {
      return;
    }
    state = state.copyWith(
      status: AgentStatus.online,
      connectionMode: ConnectionMode.rest,
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts || _socketService.isProcessing) {
      return;
    }

    _isReconnecting = true;
    _reconnectAttempts++;
    
    final delaySeconds = _calculateBackoffDelay(_reconnectAttempts);
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      await _attemptReconnect();
    });
  }

  int _calculateBackoffDelay(int attempt) {
    final baseDelay = 2;
    final maxDelay = 30;
    final delay = (baseDelay * (1 << (attempt - 1))).clamp(1, maxDelay);
    return delay;
  }

  Future<void> _attemptReconnect() async {
    if (_socketService.isProcessing) {
      _isReconnecting = false;
      return;
    }
    
    try {
      state = state.copyWith(status: AgentStatus.thinking);
      await _socketService.reconnect();
      
      _eventSub?.cancel();
      _eventSub = _socketService.events?.listen(
        _onEvent,
        onError: _onStreamError,
        onDone: _onStreamDone,
        cancelOnError: false,
      );
      
      state = state.copyWith(
        connectionMode: _socketService.mode,
        status: AgentStatus.online,
      );
      
      _reconnectAttempts = 0;
      _isReconnecting = false;
      
    } catch (e) {
      _isReconnecting = false;
      
      if (_reconnectAttempts < _maxReconnectAttempts && !_socketService.isProcessing) {
        _scheduleReconnect();
      } else {
        state = state.copyWith(
          connectionMode: ConnectionMode.rest,
          status: AgentStatus.online,
        );
      }
    }
  }

  void _onEvent(AgentEvent event) {
    final newTrace = [...state.traceLog, event];
    final trimmedTrace = newTrace.length > _maxTraceLogSize
        ? newTrace.sublist(newTrace.length - _maxTraceLogSize)
        : newTrace;

    switch (event) {
      case ConnectionEvent _:
        state = state.copyWith(traceLog: trimmedTrace);

      case StateUpdateEvent e:
        final isActive = const {
          'supervisor',
          'rag_tool',
          'firecrawl_tool',
          'predictive_tool',
          'response_node',
        }.contains(e.node);
        state = state.copyWith(
          traceLog: trimmedTrace,
          status: isActive ? AgentStatus.thinking : AgentStatus.online,
        );

      case ToolCallEvent _:
        state = state.copyWith(traceLog: trimmedTrace);

      case ToolResultEvent _:
        state = state.copyWith(traceLog: trimmedTrace);

      case TokenEvent e:
        _messageTimeoutTimer?.cancel();
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
        _messageTimeoutTimer?.cancel();
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
        _messageTimeoutTimer?.cancel();
        if (e.fatal) {
          state = state.copyWith(
            status: AgentStatus.online,
            isSending: false,
          );
        } else {
          final msg = state.currentStreamingMessage;
          if (msg != null) {
            state = state.copyWith(
              currentStreamingMessage: msg.copyWith(
                error: e.message,
                isStreaming: false,
              ),
              isSending: false,
              status: AgentStatus.online,
            );
          }
        }

      case PlanGeneratedEvent _:
        state = state.copyWith(traceLog: trimmedTrace);

      case ReflectionEvent _:
        state = state.copyWith(traceLog: trimmedTrace);
    }
  }

  void sendMessage(String text) {
    if (state.isSending || text.trim().isEmpty) return;

    _messageTimeoutTimer?.cancel();

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
      content: '',
      isStreaming: true,
      timestamp: now,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      currentStreamingMessage: assistantMsg,
      isSending: true,
      status: AgentStatus.thinking,
    );

    _messageTimeoutTimer = Timer(
      Duration(seconds: _messageTimeoutSeconds),
      () {
        if (state.isSending) {
          final msg = state.currentStreamingMessage;
          if (msg != null) {
            state = state.copyWith(
              currentStreamingMessage: msg.copyWith(
                error: 'Timeout: Server tidak merespon dalam $_messageTimeoutSeconds detik',
                isStreaming: false,
              ),
              isSending: false,
              status: AgentStatus.online,
            );
          }
        }
      },
    );

    if (state.connectionMode == ConnectionMode.realtime) {
      try {
        _socketService.sendMessage(text);
      } catch (e) {
        _messageTimeoutTimer?.cancel();
        final msg = state.currentStreamingMessage;
        if (msg != null) {
          state = state.copyWith(
            currentStreamingMessage: msg.copyWith(
              error: 'Gagal mengirim pesan: ${e.toString()}',
              isStreaming: false,
            ),
            isSending: false,
            status: AgentStatus.online,
          );
        }
        _sendRestFallback(text);
      }
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
      
      _messageTimeoutTimer?.cancel();
      
      final msg = state.currentStreamingMessage;
      if (msg != null) {
        final finalMsg = msg.copyWith(
          content: response['message'] as String? ?? '',
          isStreaming: false,
        );
        state = state.copyWith(
          messages: [...state.messages, finalMsg],
          clearStreaming: true,
          isSending: false,
          status: AgentStatus.online,
          conversationId: response['conversation_id'] as String? ??
              state.conversationId,
        );
      }
    } catch (e) {
      _messageTimeoutTimer?.cancel();
      
      final msg = state.currentStreamingMessage;
      if (msg != null) {
        state = state.copyWith(
          currentStreamingMessage: msg.copyWith(
            error: e.toString().replaceFirst('Exception: ', ''),
            isStreaming: false,
          ),
          isSending: false,
          status: AgentStatus.online,
        );
      }
    }
  }

  Future<void> reconnectWs() async {
    if (_isReconnecting || _socketService.isProcessing) return;
    
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    
    state = state.copyWith(status: AgentStatus.thinking);
    
    try {
      await _socketService.reconnect();
      
      _eventSub?.cancel();
      _eventSub = _socketService.events?.listen(
        _onEvent,
        onError: _onStreamError,
        onDone: _onStreamDone,
        cancelOnError: false,
      );
      
      state = state.copyWith(
        connectionMode: _socketService.mode,
        status: AgentStatus.online,
      );
    } catch (e) {
      state = state.copyWith(
        connectionMode: ConnectionMode.rest,
        status: AgentStatus.online,
      );
    }
  }

  void clearHistory() {
    state = const ChatState();
  }
}

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(ChatViewModel.new);

final chatPresetQueryProvider = StateProvider<String?>((ref) => null);