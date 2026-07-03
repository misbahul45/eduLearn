import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../../core/models/agent_event.dart';

class PredictionChartCard extends StatelessWidget {
  final PredictionResult prediction;

  const PredictionChartCard({
    super.key,
    required this.prediction,
  });

  @override
  Widget build(BuildContext context) {
    final passed = prediction.predictedLabel.toLowerCase() == 'lulus';
    final passedPct = passed ? prediction.confidence : 1.0 - prediction.confidence;
    final failedPct = passed ? 1.0 - prediction.confidence : prediction.confidence;

    return Card(
      color: AppColors.surface,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.analytics_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analisis Kelulusan AI',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 1,
                          centerSpaceRadius: 28,
                          sections: [
                            PieChartSectionData(
                              value: passedPct,
                              color: AppColors.success,
                              radius: 12,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: failedPct,
                              color: AppColors.error,
                              radius: 12,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            prediction.predictedLabel,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              color: passed ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LegendItem(
                        color: AppColors.success,
                        label: 'Peluang Lulus',
                        value: '${(passedPct * 100).toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 6),
                      LegendItem(
                        color: AppColors.error,
                        label: 'Peluang Gagal',
                        value: '${(failedPct * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
