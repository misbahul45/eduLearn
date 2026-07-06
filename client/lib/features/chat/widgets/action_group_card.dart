/// Action Group Card — visualisasi parallel tool execution.
///
/// Menampilkan group tool calls yang dieksekusi bersamaan:
/// - Group header dengan "Nx parallel" badge
/// - Total duration
/// - Per-tool entry dengan icon, status, duration
/// - Summary result per tool
library;
import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ActionGroupCard extends StatelessWidget {
  final ParallelToolGroup group;

  const ActionGroupCard({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: AppColors.success),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Parallel Execution',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${group.entries.length}x concurrent',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Total duration
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 11,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${group.totalDurationMs}ms',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Tool entries
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: group.entries.map((entry) {
                        return _ToolEntryTile(entry: entry);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Single tool entry
// ============================================================

class _ToolEntryTile extends StatelessWidget {
  final ParallelToolEntry entry;

  const _ToolEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final statusColor = entry.success
        ? AppColors.success
        : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tool icon
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                entry.toolIcon,
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Tool name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.toolName,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      entry.success
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 10,
                      color: statusColor,
                    ),
                    const Spacer(),
                    // Duration
                    Text(
                      '${entry.durationMs}ms',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                if (entry.summary.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.summary,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}