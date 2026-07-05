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
  bool _isProcessing = false;
  bool _isConnecting = false;
  String? _conversationId;

  ConnectionMode _mode = ConnectionMode.realtime;
  ConnectionMode get mode => _mode;

  AgentSocketService({
    required this._storage,
    String? baseUrl,
  }) : _baseUrl = baseUrl ?? AppConfig.wsBaseUrl;

  Stream<AgentEvent>? get events => _controller?.stream;
  String? get conversationId => _conversationId;
  bool get isProcessing => _isProcessing;

  void setProcessing(bool value) {
    _isProcessing = value;
  }

  Future<void> connect() async {
    if (_disposed || _isConnecting || _channel != null) return;
    _isConnecting = true;
    _controller ??= StreamController<AgentEvent>.broadcast();

    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        _isConnecting = false;
        return;
      }
      if (_disposed || _channel != null) {
        _isConnecting = false;
        return;
      }

      final uri = Uri.parse('$_baseUrl?token=$token');
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _mode = ConnectionMode.realtime;

      channel.stream.listen(
        (raw) {
          _reconnectAttempt = 0;
          _onData(raw);
        },
        onError: (_) {
          if (identical(_channel, channel)) {
            _channel = null;
            _scheduleReconnect();
          }
        },
        onDone: () {
          if (identical(_channel, channel)) {
            _channel = null;
            _scheduleReconnect();
          }
        },
        cancelOnError: false,
      );
    } catch (_) {
      _channel = null;
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
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
      if (event is FinalEvent) {
        _isProcessing = false;
        if (event.conversationId.isNotEmpty) {
          _conversationId = event.conversationId;
        }
      } else if (event is AgentErrorEvent && event.fatal) {
        _isProcessing = false;
      }
      _controller?.add(event);
    }
  }

  void sendMessage(String text) {
    if (_channel == null || _mode != ConnectionMode.realtime) return;
    _isProcessing = true;
    try {
      _channel!.sink.add(
        WsMessageBuilder.userMessage(
          message: text,
          conversationId: _conversationId,
        ),
      );
    } catch (_) {
      _isProcessing = false;
      _channel = null;
      _scheduleReconnect();
      rethrow;
    }
  }

  void listenForeground() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork &&
          _mode == ConnectionMode.realtime &&
          _channel == null &&
          !_isConnecting) {
        _reconnectAttempt = 0;
        connect();
      }
    });
  }

  void _scheduleReconnect() {
    if (_disposed || _mode == ConnectionMode.rest) return;

    _reconnectAttempt++;
    if (_reconnectAttempt > 3) {
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