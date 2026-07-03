import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/agent_event.dart';
import '../network/ws_event_parser.dart';
import '../network/ws_message_builder.dart';

enum ConnectionMode { realtime, rest }

class AgentSocketService {
  final FlutterSecureStorage _storage;
  final String _baseUrl;

  WebSocketChannel? _channel;
  StreamController<AgentEvent>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  String? _conversationId;

  ConnectionMode _mode = ConnectionMode.realtime;
  ConnectionMode get mode => _mode;

  AgentSocketService({
    required this._storage,
    String? baseUrl,
  })  : _baseUrl = baseUrl ?? AppConfig.wsBaseUrl;

  Stream<AgentEvent>? get events => _controller?.stream;
  String? get conversationId => _conversationId;

  Future<void> connect() async {
    if (_disposed) return;
    _controller ??= StreamController<AgentEvent>.broadcast();

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return;

      final uri = Uri.parse('$_baseUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _mode = ConnectionMode.realtime;
      _reconnectAttempt = 0;

      _channel!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    final json = jsonDecode(raw as String) as Map<String, dynamic>;
    final type = json['type'] as String?;

    if (type == 'ping') {
      _channel?.sink.add(WsMessageBuilder.pong());
      return;
    }

    final event = WsEventParser.parse(json);
    if (event != null) {
      if (event is FinalEvent && event.conversationId.isNotEmpty) {
        _conversationId = event.conversationId;
      }
      _controller?.add(event);
    }
  }

  void sendMessage(String text) {
    if (_channel == null || _mode != ConnectionMode.realtime) return;
    _channel!.sink.add(
      WsMessageBuilder.userMessage(
        message: text,
        conversationId: _conversationId,
      ),
    );
  }

  void listenForeground() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasNetwork = results.any(
        (r) => r != ConnectivityResult.none,
      );
      if (hasNetwork && _mode == ConnectionMode.realtime && _channel == null) {
        _reconnectAttempt = 0;
        connect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_disposed || _mode == ConnectionMode.rest) return;
    _channel = null;

    _reconnectAttempt++;
    if (_reconnectAttempt >= 3) {
      _mode = ConnectionMode.rest;
      return;
    }

    const delays = [1, 3, 8];
    final delay = delays[(_reconnectAttempt - 1).clamp(0, delays.length - 1)];
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  Future<void> reconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempt = 0;
    _mode = ConnectionMode.realtime;
    await _channel?.sink.close();
    _channel = null;
    await connect();
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _connectivitySub?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}
