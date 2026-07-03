import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final void Function(String text) onQuickSend;

  const EmptyState({
    super.key,
    required this.onQuickSend,
  });

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      ('Jelaskan neural network', 'Jelaskan neural network'),
      ('Prediksi kelulusanku', 'Prediksi kelulusanku'),
      ('Berita AI terbaru 2026', 'Berita AI terbaru 2026'),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 64,
              color: AppColors.textHint.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Mulai belajar dengan AI', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tanya apapun seputar materi pembelajaran',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ActionChip(
                  label: Text(
                    s.$1,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  onPressed: () => onQuickSend(s.$2),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
