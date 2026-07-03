import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/prediction_providers.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestPredictionProvider);
    final analysisAsync = ref.watch(predictionAnalysisProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(latestPredictionProvider);
        ref.invalidate(predictionAnalysisProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text('Analisis Pembelajaran', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.sm),
          const Text('Pantau perkembangan belajarmu', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.lg),

          analysisAsync.when(
            data: (analysis) {
              if (analysis == null) {
                return _buildEmptyAnalysis(context);
              }
              return _buildAnalysisCards(context, analysis);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(context, e.toString()),
          ),

          const SizedBox(height: AppSpacing.lg),
          const Text('Prediksi Terakhir', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),

          latestAsync.when(
            data: (pred) {
              if (pred == null || pred.label == '-') {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(Icons.insights_rounded, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Belum ada prediksi', style: AppTextStyles.subtitle),
                      ],
                    ),
                  ),
                );
              }
              return _buildLatestPrediction(context, pred.label, pred.probability);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildErrorState(context, e.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCards(BuildContext context, dynamic analysis) {
    final passedCount = analysis.passedCount as int;
    final failedCount = analysis.failedCount as int;
    final total = analysis.totalPredictions as int;
    final passRate = analysis.passRate as double;
    final avgProb = analysis.avgProbability as double;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(
              icon: Icons.check_circle_rounded,
              value: '$passedCount',
              label: 'Lulus',
              color: AppColors.success,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatCard(
              icon: Icons.cancel_rounded,
              value: '$failedCount',
              label: 'Tidak Lulus',
              color: AppColors.error,
            )),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _StatCard(
              icon: Icons.analytics_rounded,
              value: '$total',
              label: 'Total',
              color: AppColors.accentBlue,
            )),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tingkat Kelulusan', style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: LinearProgressIndicator(
                    value: passRate / 100,
                    minHeight: 12,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                      passRate >= 70 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('${passRate.toStringAsFixed(1)}%', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rata-rata probabilitas:', style: AppTextStyles.caption),
                    Text('${(avgProb * 100).toStringAsFixed(1)}%', style: AppTextStyles.body),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestPrediction(BuildContext context, String label, double probability) {
    final passed = label == 'Lulus';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: (passed ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.trending_down_rounded,
                color: passed ? AppColors.success : AppColors.error,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: $label', style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Probabilitas: ${(probability * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalysis(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: AppColors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Belum ada data analisis', style: AppTextStyles.subtitle),
            const Text('Lakukan prediksi untuk melihat hasil', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Gagal memuat data', style: AppTextStyles.subtitle),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
