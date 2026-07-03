import 'dart:convert';

class WsMessageBuilder {
  WsMessageBuilder._();

  static String userMessage({
    required String message,
    required String? conversationId,
  }) {
    return jsonEncode({
      'type': 'user_message',
      'message': message,
      'conversation_id': conversationId,
    });
  }

  static String pong() => jsonEncode({'type': 'pong'});
}
