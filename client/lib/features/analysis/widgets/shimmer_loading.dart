import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(width: 200, height: 20, decoration: _shimmer()),
        const SizedBox(height: AppSpacing.md),
        Container(
            height: 180,
            decoration: _shimmer(
                boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
        const SizedBox(height: AppSpacing.xl),
        Container(
            height: 200,
            decoration: _shimmer(
                boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
        const SizedBox(height: AppSpacing.lg),
        Container(
            height: 200,
            decoration: _shimmer(
                boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
      ],
    );
  }

  BoxDecoration _shimmer(
      {BoxShape boxShape = BoxShape.rectangle, double borderRadius = 0}) {
    return BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.5),
      borderRadius: boxShape == BoxShape.rectangle
          ? BorderRadius.circular(borderRadius)
          : null,
      shape: boxShape,
    );
  }
}
