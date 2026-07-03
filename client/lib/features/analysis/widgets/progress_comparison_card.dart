import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/analysis_viewmodel.dart';

class ProgressComparisonCard extends StatelessWidget {
  final ProgressComparison? comparison;

  const ProgressComparisonCard({
    super.key,
    this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: comparison == null
            ? Center(
                child: Text('Belum cukup data untuk perbandingan',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Probabilitas kemarin',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          Text(
                              '${(comparison!.yesterdayProbability * 100).toStringAsFixed(0)}%',
                              style: AppTextStyles.h1),
                        ],
                      ),
                      Icon(
                        comparison!.delta > 0
                            ? Icons.trending_up_rounded
                            : comparison!.delta < 0
                                ? Icons.trending_down_rounded
                                : Icons.remove_rounded,
                        color: comparison!.delta > 0
                            ? AppColors.success
                            : comparison!.delta < 0
                                ? AppColors.error
                                : AppColors.textSecondary,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Probabilitas hari ini',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary)),
                          Text(
                            '${(comparison!.todayProbability * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.h1.copyWith(
                              color: comparison!.delta > 0
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: comparison!.todayProbability,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        comparison!.todayProbability >= 0.5
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    comparison!.delta > 0
                        ? 'Naik ${(comparison!.delta * 100).toStringAsFixed(1)}%'
                        : comparison!.delta < 0
                            ? 'Turun ${(comparison!.delta.abs() * 100).toStringAsFixed(1)}%'
                            : 'Tidak ada perubahan',
                    style: AppTextStyles.caption.copyWith(
                      color: comparison!.delta > 0
                          ? AppColors.success
                          : comparison!.delta < 0
                              ? AppColors.error
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
