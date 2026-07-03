import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/knowledge_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class KnowledgeUploadSheet extends ConsumerStatefulWidget {
  const KnowledgeUploadSheet({super.key});

  @override
  ConsumerState<KnowledgeUploadSheet> createState() => _KnowledgeUploadSheetState();
}

class _KnowledgeUploadSheetState extends ConsumerState<KnowledgeUploadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt', 'md'],
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submitUpload() async {
    if (_selectedFile == null || _selectedFile!.path == null) return;
    if (_selectedFile!.size > 20 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File maksimal 20 MB')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final service = ref.read(knowledgeServiceProvider);
      await service.uploadDocument(
        filePath: _selectedFile!.path!,
        fileName: _selectedFile!.name,
        title: _titleCtrl.text,
        author: _authorCtrl.text,
        description: _descCtrl.text,
        tags: _tagsCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File diupload, sedang diproses...')),
        );
        ref.invalidate(knowledgeDocumentsProvider);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map).values.first.toString()
          : 'Gagal upload file';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upload Materi', style: AppTextStyles.h2),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Format yang didukung: PDF, DOCX, TXT, MD (max 20MB)',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Judul (opsional)',
                    hintText: 'Pengantar Deep Learning',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _authorCtrl,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Penulis (opsional)',
                    hintText: 'Dr. X',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _descCtrl,
                  enabled: !_isUploading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    hintText: 'Materi tentang...',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tagsCtrl,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Tags (opsional, pisahkan koma)',
                    hintText: 'deep_learning, neural_network',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _isUploading ? null : _pickFile,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border.all(
                  color: _selectedFile == null ? AppColors.border : AppColors.primary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
                    size: 36,
                    color: _selectedFile == null ? AppColors.textHint : AppColors.success,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _selectedFile?.name ?? 'Tap untuk pilih file',
                    style: AppTextStyles.label,
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(0)} KB',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: (_selectedFile != null && !_isUploading) ? _submitUpload : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary),
                  )
                : const Text('Upload', style: AppTextStyles.button),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
