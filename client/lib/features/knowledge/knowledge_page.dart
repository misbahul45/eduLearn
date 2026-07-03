import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class KnowledgePage extends ConsumerStatefulWidget {
  const KnowledgePage({super.key});

  @override
  ConsumerState<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends ConsumerState<KnowledgePage> {
  final List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/knowledge');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _documents = (data['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat dokumen')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload file akan segera hadir')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) {
                      final doc = _documents[index];
                      return _buildDocCard(doc);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          const Text('Belum ada materi', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Pengajar dapat menambahkan materi\npembelajaran di sini',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final status = doc['status'] as String? ?? 'unknown';
    final fileName = doc['file_name'] as String? ?? '';

    final statusColor = switch (status) {
      'ready' => AppColors.success,
      'processing' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textHint,
    };

    final statusLabel = switch (status) {
      'ready' => 'Siap',
      'processing' => 'Diproses',
      'failed' => 'Gagal',
      _ => status,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          fileName.endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
          color: AppColors.accentBlue,
        ),
        title: Text(doc['title'] as String? ?? fileName),
        subtitle: Text(
          '${(doc['file_size_bytes'] as int? ?? 0) > 1024 ? '${((doc['file_size_bytes'] as int? ?? 0) / 1024).toStringAsFixed(1)} KB' : '${doc['file_size_bytes'] ?? 0} B'}  •  $statusLabel',
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              try {
                final api = ref.read(apiClientProvider);
                await api.delete('/knowledge/${doc['document_id']}');
                _loadDocuments();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus dokumen')),
                  );
                }
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}
