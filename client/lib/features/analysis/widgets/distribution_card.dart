import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/models/prediction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class DistributionCard extends StatelessWidget {
  final Prediction latest;

  const DistributionCard({
    super.key,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final passed = latest.isPassed;
    final passedPct = passed ? latest.confidence : 1.0 - latest.confidence;
    final failedPct = passed ? 1.0 - latest.confidence : latest.confidence;
    final centerLabel = passed ? 'Lulus' : 'Tidak Lulus';
    final centerValue = '${(passedPct * 100).toStringAsFixed(0)}%';

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: passedPct,
                          color: AppColors.success,
                          radius: 40,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: failedPct,
                          color: AppColors.error,
                          radius: 40,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(centerValue,
                          style: AppTextStyles.h1.copyWith(fontSize: 28)),
                      Text(centerLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendRow(
                      color: AppColors.success,
                      label: 'Lulus',
                      value: '${(passedPct * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: AppSpacing.sm),
                  LegendRow(
                      color: AppColors.error,
                      label: 'Tidak Lulus',
                      value: '${(failedPct * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const LegendRow({
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
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        Text(value, style: AppTextStyles.subtitle),
      ],
    );
  }
}
