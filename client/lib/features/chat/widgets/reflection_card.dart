import 'package:flutter/material.dart';

import '../../../core/models/reflection_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ReflectionCard extends StatelessWidget {
  final ReflectionData data;
  final bool compact;

  const ReflectionCard({
    super.key,
    required this.data,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final qualityColor = _qualityColor(data.qualityScore);
    final actionColor = data.needsIteration
        ? AppColors.warning
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: qualityColor.withValues(alpha: 0.05),
        border: Border.all(
          color: qualityColor.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: qualityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: compact
                    ? _buildCompact(qualityColor, actionColor)
                    : _buildFull(qualityColor, actionColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Full layout
  // ============================================================

  Widget _buildFull(Color qualityColor, Color actionColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 14,
              color: qualityColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Self-Check',
              style: AppTextStyles.caption.copyWith(
                color: qualityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Quality score bar
            _QualityBar(
              score: data.qualityScore,
              color: qualityColor,
            ),
            const SizedBox(width: 8),
            Text(
              data.qualityPercent,
              style: TextStyle(
                fontSize: 12,
                color: qualityColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Next action badge
        Row(
          children: [
            _ActionBadge(
              action: data.nextAction,
              color: actionColor,
            ),
            const SizedBox(width: 6),
            if (data.planCompleted)
              _MiniBadge(
                icon: Icons.check_circle_outline,
                label: 'Plan complete',
                color: AppColors.success,
              )
            else
              _MiniBadge(
                icon: Icons.pending,
                label: 'Plan incomplete',
                color: AppColors.warning,
              ),
            const SizedBox(width: 6),
            if (data.infoSufficient)
              _MiniBadge(
                icon: Icons.info_outline,
                label: 'Info sufficient',
                color: AppColors.success,
              ),
          ],
        ),

        // Reason
        if (data.reason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            data.reason,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
        ],

        // Missing aspects
        if (data.missingAspects.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: data.missingAspects.map((aspect) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      size: 10,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Missing: $aspect',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // Compact layout (inline, untuk chat bubble)
  // ============================================================

  Widget _buildCompact(Color qualityColor, Color actionColor) {
    return Row(
      children: [
        Icon(
          Icons.fact_check_outlined,
          size: 12,
          color: qualityColor,
        ),
        const SizedBox(width: 4),
        Text(
          'Self-Check',
          style: AppTextStyles.caption.copyWith(
            color: qualityColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          data.qualityPercent,
          style: TextStyle(
            fontSize: 11,
            color: qualityColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: actionColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            data.nextAction,
            style: TextStyle(
              fontSize: 9,
              color: actionColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (data.missingAspects.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            '(${data.missingAspects.length} missing)',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // Helpers
  // ============================================================

  Color _qualityColor(double score) {
    if (score >= 0.8) return AppColors.success;
    if (score >= 0.6) return AppColors.accentBlue;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
}

// ============================================================
// Sub-widgets
// ============================================================

class _QualityBar extends StatelessWidget {
  final double score; // 0.0 - 1.0
  final Color color;

  const _QualityBar({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  final String action; // iterate | respond
  final Color color;

  const _ActionBadge({required this.action, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = action == 'iterate' ? 'Need more info' : 'Ready to answer';
    final icon = action == 'iterate'
        ? Icons.refresh
        : Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }
}