import 'package:dio/dio.dart';

import '../models/agent_event.dart';
import 'api_client.dart';

class ChatRepository {
  final ApiClient _api;

  ChatRepository(this._api);

  Future<Map<String, dynamic>> sendMessage(String text, {String? conversationId}) async {
    try {
      final response = await _api.post('/chat', data: {
        'message': text,
        if (conversationId != null) 'conversation_id': conversationId,
      });
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['detail'] as String? ?? e.message
          : e.message;
      throw Exception(msg);
    }
    throw Exception('Gagal mengirim pesan');
  }
}
