import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/knowledge_providers.dart';
import '../../../core/services/knowledge_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../knowledge_upload_sheet.dart';
import 'profile_shimmers.dart';

class KnowledgeManagementSection extends ConsumerWidget {
  const KnowledgeManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(knowledgeDocumentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Materi Knowledge Base', style: AppTextStyles.h2),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Upload'),
              onPressed: () => _showUploadSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        docsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return EmptyKnowledge(
                message:
                    'Belum ada materi. Upload file PDF/DOCX/TXT/MD untuk mulai.',
                onUpload: () => _showUploadSheet(context),
              );
            }
            return Column(
              children: docs
                  .map((doc) => KnowledgeDocItem(doc: doc))
                  .toList(),
            );
          },
          loading: () => const KnowledgeSkeleton(),
          error: (e, _) => Center(
            child: Text(
              'Gagal memuat: $e',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const KnowledgeUploadSheet(),
    );
  }
}

class EmptyKnowledge extends StatelessWidget {
  final String message;
  final VoidCallback onUpload;

  const EmptyKnowledge({
    super.key,
    required this.message,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeDocItem extends ConsumerWidget {
  final KnowledgeDocument doc;

  const KnowledgeDocItem({
    super.key,
    required this.doc,
  });

  IconData _fileIcon() {
    if (doc.fileName.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (doc.fileName.endsWith('.docx')) return Icons.description_rounded;
    if (doc.fileName.endsWith('.md')) return Icons.code_rounded;
    return Icons.text_snippet_rounded;
  }

  Color _statusColor() {
    return switch (doc.status) {
      'ready' => AppColors.success,
      'processing' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textHint,
    };
  }

  String _statusLabel() {
    return switch (doc.status) {
      'ready' => 'Siap',
      'processing' => 'Diproses',
      'failed' => 'Gagal',
      _ => doc.status,
    };
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus materi'),
        content: const Text(
          'Hapus materi ini? Siswa tidak akan bisa akses referensi lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(knowledgeServiceProvider)
                    .deleteDocument(doc.documentId);
                ref.invalidate(knowledgeDocumentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Materi berhasil dihapus'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus materi'),
                    ),
                  );
                }
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: Icon(_fileIcon(), color: AppColors.accentBlue),
          title: Text(
            doc.title.isNotEmpty ? doc.title : doc.fileName,
            style: AppTextStyles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${doc.totalChunks} chunks · '
            '${doc.fileSizeBytes > 1024 ? '${(doc.fileSizeBytes / 1024).toStringAsFixed(0)} KB' : '${doc.fileSizeBytes} B'}',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(context, ref);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: doc.status == 'failed' && doc.errorMessage != null
              ? () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Error',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            doc.errorMessage!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }
}
