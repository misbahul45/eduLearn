import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/knowledge_service.dart';
import 'auth_providers.dart';

final knowledgeServiceProvider = Provider<KnowledgeService>((ref) {
  return KnowledgeService(ref.watch(apiClientProvider));
});

final knowledgeDocumentsProvider = FutureProvider.autoDispose<List<KnowledgeDocument>>((ref) {
  return ref.watch(knowledgeServiceProvider).listDocuments();
});
