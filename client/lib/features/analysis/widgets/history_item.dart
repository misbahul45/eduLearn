import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/analysis_viewmodel.dart';

class HistoryItem extends StatelessWidget {
  final PredictionHistoryItem item;

  const HistoryItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final passed = item.probability >= 0.5;
    final color = passed ? AppColors.success : AppColors.error;
    final label = passed ? 'Lulus' : 'Tidak Lulus';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final dateStr = '${item.date.day} ${months[item.date.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text(dateStr,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w500, color: color)),
              ),
              Text('${(item.probability * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
