import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/agent_event.dart';

enum ConnectionMode { realtime, rest }

class AgentSocketService {
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  WebSocketChannel? _channel;
  StreamController<AgentEvent>? _controller;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;

  ConnectionMode mode = ConnectionMode.realtime;

  AgentSocketService({
    required FlutterSecureStorage storage,
    String baseUrl = 'wss://api.edulearn.ai/ws/v1/chat',
  })  : _storage = storage,
        _baseUrl = baseUrl;

  Stream<AgentEvent>? get events => _controller?.stream;

  Future<void> connect() async {
    if (_disposed) return;
    _controller ??= StreamController<AgentEvent>.broadcast();

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      final uri = Uri.parse('$_baseUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);
      mode = ConnectionMode.realtime;
      _reconnectAttempt = 0;

      _channel!.stream.listen(
        (data) {
          final json = jsonDecode(data as String) as Map<String, dynamic>;
          final event = _parseEvent(json);
          if (event != null) {
            _controller!.add(event);
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void sendMessage(String text) {
    if (_channel != null && mode == ConnectionMode.realtime) {
      _channel!.sink.add(jsonEncode({'message': text}));
    }
  }

  void _scheduleReconnect() {
    if (_disposed || mode == ConnectionMode.rest) return;

    _reconnectAttempt++;
    if (_reconnectAttempt >= 3) {
      mode = ConnectionMode.rest;
      return;
    }

    final delay = [1, 2, 4, 8, 16, 30]
        .elementAtOrNull(_reconnectAttempt - 1) ?? 30;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  Future<void> reconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    await _channel?.sink.close();
    mode = ConnectionMode.realtime;
    await connect();
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }

  AgentEvent? _parseEvent(Map<String, dynamic> json) {
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
                ? CitationMeta.fromJson(json['metadata'] as Map<String, dynamic>)
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
                ? PredictionResult.fromJson(json['data'] as Map<String, dynamic>)
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
