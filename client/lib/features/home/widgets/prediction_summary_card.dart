import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/prediction.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PredictionSummaryCard extends StatelessWidget {
  final Prediction prediction;

  const PredictionSummaryCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final passed = prediction.isPassed;
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prediksi Kelulusan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    prediction.predictedLabel,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  Text(
                    'Confidence ${(prediction.confidence * 100).toStringAsFixed(0)}% · Model: Deep MLP',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              passed ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 48,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final Prediction prediction;

  const InsightCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final passed = prediction.isPassed;
    return Card(
      color: passed
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.warning.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: passed ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                passed
                    ? 'Kerja bagus! Pertahankan ritme belajar 30 menit/hari.'
                    : 'Perbanyak quiz score dan latihan soal untuk meningkatkan prediksi.',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyPredictionCard extends StatelessWidget {
  const EmptyPredictionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Belum ada prediksi',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Mulai chat dengan AI untuk dapatkan prediksi kelulusanmu.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutes.chatTab),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Tanya AI'),
            ),
          ],
        ),
      ),
    );
  }
}
