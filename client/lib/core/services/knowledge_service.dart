import 'package:dio/dio.dart';
import 'api_client.dart';

class KnowledgeDocument {
  final String documentId;
  final String title;
  final String fileName;
  final int fileSizeBytes;
  final String status;
  final int totalChunks;
  final String? errorMessage;

  const KnowledgeDocument({
    required this.documentId,
    required this.title,
    required this.fileName,
    required this.fileSizeBytes,
    required this.status,
    required this.totalChunks,
    this.errorMessage,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      documentId: json['document_id'] as String? ?? '',
      title: json['title'] as String? ?? json['file_name'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      status: json['status'] as String? ?? 'unknown',
      totalChunks: json['total_chunks'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }
}

class KnowledgeService {
  final ApiClient _api;

  KnowledgeService(this._api);

  Future<List<KnowledgeDocument>> listDocuments() async {
    final response = await _api.get('/knowledge');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<KnowledgeDocument> getDocument(String documentId) async {
    final response = await _api.get('/knowledge/$documentId');
    return KnowledgeDocument.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String fileName,
    String? title,
    String? author,
    String? description,
    String? tags,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      if (title != null && title.isNotEmpty) 'title': title,
      if (author != null && author.isNotEmpty) 'author': author,
      if (description != null && description.isNotEmpty) 'description': description,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
    });
    final response = await _api.post('/knowledge/upload', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDocument(String documentId) async {
    await _api.delete('/knowledge/$documentId');
  }
}
