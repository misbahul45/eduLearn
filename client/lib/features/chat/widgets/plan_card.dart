/// Plan Card — visualisasi execution plan dari Planner node.
///
/// Menampilkan:
/// - Step list dengan status icon (⏳ pending, 🔄 running, ✅ done)
/// - Dependency arrows antar step
/// - Parallel badge untuk step yang bisa parallel
/// - Tool icon per step
library;
import 'package:flutter/material.dart';

import '../../../core/models/plan_step.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PlanCard extends StatelessWidget {
  final List<PlanStep> steps;
  final String reasoning;
  final bool initiallyExpanded;

  const PlanCard({
    super.key,
    required this.steps,
    this.reasoning = '',
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    final pendingCount = steps.where((s) => s.status == 'pending').length;
    final doneCount = steps.where((s) => s.status == 'done').length;
    final runningCount = steps.where((s) => s.status == 'running').length;
    final parallelEligible =
        steps.where((s) => s.isParallelEligible).length;

    return _ExpandablePlanCard(
      steps: steps,
      reasoning: reasoning,
      initiallyExpanded: initiallyExpanded,
      pendingCount: pendingCount,
      doneCount: doneCount,
      runningCount: runningCount,
      parallelEligible: parallelEligible,
    );
  }
}

class _ExpandablePlanCard extends StatefulWidget {
  final List<PlanStep> steps;
  final String reasoning;
  final bool initiallyExpanded;
  final int pendingCount;
  final int doneCount;
  final int runningCount;
  final int parallelEligible;

  const _ExpandablePlanCard({
    required this.steps,
    required this.reasoning,
    required this.initiallyExpanded,
    required this.pendingCount,
    required this.doneCount,
    required this.runningCount,
    required this.parallelEligible,
  });

  @override
  State<_ExpandablePlanCard> createState() => _ExpandablePlanCardState();
}

class _ExpandablePlanCardState extends State<_ExpandablePlanCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded ||
        widget.runningCount > 0 ||
        widget.pendingCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(width: 3, color: AppColors.accentBlue),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 14,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Execution Plan',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Progress badge
                          _ProgressBadge(
                            done: widget.doneCount,
                            running: widget.runningCount,
                            pending: widget.pendingCount,
                            total: widget.steps.length,
                          ),
                          const Spacer(),
                          if (widget.parallelEligible > 1) ...[
                            _ParallelBadge(
                                count: widget.parallelEligible),
                            const SizedBox(width: 4),
                          ],
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              size: 16,
                              color: AppColors.textHint.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _expanded
                        ? _buildExpandedContent()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),

        // Reasoning (if any)
        if (widget.reasoning.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textHint.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 12,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.reasoning,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Steps list
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: widget.steps.asMap().entries.map((entry) {
              final step = entry.value;
              final isLast = entry.key == widget.steps.length - 1;
              return _PlanStepTile(
                step: step,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Step tile
// ============================================================

class _PlanStepTile extends StatelessWidget {
  final PlanStep step;
  final bool isLast;

  const _PlanStepTile({
    required this.step,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(step.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status icon + connector line
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.15),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Center(
                  child: step.status == 'running'
                      ? SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: statusColor,
                          ),
                        )
                      : Text(
                          step.statusIcon,
                          style: const TextStyle(fontSize: 9),
                        ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 20,
                  color: AppColors.border,
                ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Step content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.toolIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Step ${step.stepId}',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        step.tool,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (step.isParallelEligible && step.tool != 'respond') ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.call_split,
                        size: 10,
                        color: AppColors.accentBlue.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  step.description.isEmpty
                      ? '(no description)'
                      : step.description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (step.resultSummary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.resultSummary,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => AppColors.textHint,
        'running' => AppColors.accentBlue,
        'done' => AppColors.success,
        'skipped' => AppColors.textHint,
        'failed' => AppColors.error,
        _ => AppColors.textHint,
      };
}

// ============================================================
// Badges
// ============================================================

class _ProgressBadge extends StatelessWidget {
  final int done;
  final int running;
  final int pending;
  final int total;

  const _ProgressBadge({
    required this.done,
    required this.running,
    required this.pending,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = done == total;
    final color = allDone
        ? AppColors.success
        : running > 0
            ? AppColors.accentBlue
            : AppColors.textHint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        allDone ? '✓ done' : '$done/$total',
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ParallelBadge extends StatelessWidget {
  final int count;

  const _ParallelBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.call_split,
            size: 9,
            color: AppColors.accentBlue,
          ),
          const SizedBox(width: 2),
          Text(
            '${count}x parallel',
            style: TextStyle(
              fontSize: 9,
              color: AppColors.accentBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}