import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class StrengthCard extends StatelessWidget {
  final String text;

  const StrengthCard({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text('Kekuatan',
                    style:
                        AppTextStyles.subtitle.copyWith(color: AppColors.success)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(text, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
