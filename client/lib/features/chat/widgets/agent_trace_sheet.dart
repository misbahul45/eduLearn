import 'package:flutter/material.dart';

import '../../../core/models/agent_event.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/agent_socket_service.dart';

class AgentTraceSheet extends StatefulWidget {
  final List<AgentEvent> traceLog;
  final ConnectionMode connectionMode;
  final VoidCallback onClose;
  final List<PlanStep>? currentPlan;
  final List<ReflectionData>? reflections;

  const AgentTraceSheet({
    super.key,
    required this.traceLog,
    required this.connectionMode,
    required this.onClose,
    this.currentPlan,
    this.reflections,
  });

  @override
  State<AgentTraceSheet> createState() => _AgentTraceSheetState();
}

class _AgentTraceSheetState extends State<AgentTraceSheet> {
  String? _activeFilter;

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _applyFilter(widget.traceLog, _activeFilter);
    final phaseGroups = _groupByPhase(filteredEvents);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Phase timeline
              _buildPhaseTimeline(phaseGroups),

              // Filter chips
              _buildFilterChips(),

              const SizedBox(height: AppSpacing.xs),

              // Events list
              Expanded(
                child: phaseGroups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: phaseGroups.length,
                        itemBuilder: (context, index) {
                          return _PhaseGroupCard(
                            group: phaseGroups[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 18),
          const SizedBox(width: 8),
          const Text('Agent Trace', style: AppTextStyles.subtitle),
          const Spacer(),
          // Connection mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: widget.connectionMode == ConnectionMode.realtime
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              widget.connectionMode == ConnectionMode.realtime
                  ? 'Realtime'
                  : 'REST',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: widget.connectionMode == ConnectionMode.realtime
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${widget.traceLog.length} events',
            style: AppTextStyles.caption,
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Phase timeline (horizontal indicators)
  // ============================================================

  Widget _buildPhaseTimeline(List<PhaseGroup> groups) {
    final phases = ['planner', 'supervisor', 'tools', 'reflector', 'respond'];
    final phaseStatus = <String, String>{};

    for (final phase in phases) {
      final hasStarted = groups.any((g) => g.phase == phase);
      final hasCompleted = groups.any(
          (g) => g.phase == phase && g.events.any((e) => e is! StateUpdateEvent));
      final hasError =
          groups.any((g) => g.phase == phase && g.events.any((e) => e is AgentErrorEvent));

      phaseStatus[phase] = hasError
          ? 'error'
          : hasCompleted
              ? 'done'
              : hasStarted
                  ? 'active'
                  : 'pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (int i = 0; i < phases.length; i++) ...[
            _PhaseChip(
              phase: phases[i],
              status: phaseStatus[phases[i]]!,
            ),
            if (i < phases.length - 1)
              Expanded(
                child: _PhaseConnector(
                  status: phaseStatus[phases[i]]!,
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Filter chips
  // ============================================================

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All', null),
      ('plan', 'Plan', 'planner'),
      ('tools', 'Tools', 'tools'),
      ('reflection', 'Reflection', 'reflector'),
      ('error', 'Errors', 'error'),
    ];

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: filters.map((f) {
          final isActive = _activeFilter == f.$2 ||
              (_activeFilter == null && f.$1 == 'all');
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: FilterChip(
              label: Text(f.$2, style: const TextStyle(fontSize: 11)),
              selected: isActive,
              onSelected: (selected) {
                setState(() {
                  _activeFilter = selected ? f.$2 : null;
                  if (f.$1 == 'all') _activeFilter = null;
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              backgroundColor: AppColors.background,
              side: BorderSide(
                color: isActive
                    ? AppColors.primary
                    : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // Empty state
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _activeFilter == null
                ? 'Belum ada trace'
                : 'Tidak ada event untuk filter "$_activeFilter"',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kirim pesan untuk melihat agent bekerja',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Grouping logic
  // ============================================================

  List<AgentEvent> _applyFilter(List<AgentEvent> events, String? filter) {
    if (filter == null) return events;

    return switch (filter) {
      'Plan' => events.where((e) => e.phase == 'planner').toList(),
      'Tools' => events.where((e) => e.phase == 'tools').toList(),
      'Reflection' => events.where((e) => e.phase == 'reflector').toList(),
      'Errors' => events.whereType<AgentErrorEvent>().toList(),
      _ => events,
    };
  }

  List<PhaseGroup> _groupByPhase(List<AgentEvent> events) {
    if (events.isEmpty) return [];

    final groups = <PhaseGroup>[];
    final phaseOrder = ['planner', 'supervisor', 'tools', 'reflector', 'respond', 'system'];

    for (final phase in phaseOrder) {
      final phaseEvents = events.where((e) => e.phase == phase).toList();
      if (phaseEvents.isEmpty) continue;

      // Untuk phase tools, sub-group by parallel_group
      if (phase == 'tools') {
        final subGroups = _subGroupToolsByParallel(phaseEvents);
        for (final sub in subGroups) {
          groups.add(sub);
        }
      } else {
        // Cek apakah ada multiple iterations
        final iterations = <int>{};
        for (final e in phaseEvents) {
          if (e is StateUpdateEvent) iterations.add(e.iteration);
          if (e is ToolCallEvent) iterations.add(e.iteration);
          if (e is ToolResultEvent) iterations.add(e.iteration);
        }

        if (iterations.length > 1) {
          // Multiple iterations — group by iteration
          for (final iter in iterations.toList()..sort()) {
            final iterEvents = phaseEvents.where((e) {
              if (e is StateUpdateEvent) return e.iteration == iter;
              if (e is ToolCallEvent) return e.iteration == iter;
              if (e is ToolResultEvent) return e.iteration == iter;
              return true;
            }).toList();
            if (iterEvents.isNotEmpty) {
              groups.add(PhaseGroup(
                phase: phase,
                iteration: iter,
                events: iterEvents,
                parallelGroup: null,
              ));
            }
          }
        } else {
          groups.add(PhaseGroup(
            phase: phase,
            iteration: iterations.isNotEmpty ? iterations.first : 0,
            events: phaseEvents,
            parallelGroup: null,
          ));
        }
      }
    }

    return groups;
  }

  List<PhaseGroup> _subGroupToolsByParallel(List<AgentEvent> events) {
    final groups = <PhaseGroup>[];
    final parallelMap = <String, List<AgentEvent>>{};
    final nonParallel = <AgentEvent>[];

    for (final e in events) {
      String? pg;
      if (e is ToolCallEvent) pg = e.parallelGroup;
      if (e is ToolResultEvent) pg = e.parallelGroup;

      if (pg != null) {
        parallelMap.putIfAbsent(pg, () => []).add(e);
      } else {
        nonParallel.add(e);
      }
    }

    // Non-parallel events first (sequential)
    if (nonParallel.isNotEmpty) {
      groups.add(PhaseGroup(
        phase: 'tools',
        iteration: 0,
        events: nonParallel,
        parallelGroup: null,
      ));
    }

    // Then parallel groups
    for (final entry in parallelMap.entries) {
      groups.add(PhaseGroup(
        phase: 'tools',
        iteration: 0,
        events: entry.value,
        parallelGroup: entry.key,
      ));
    }

    return groups;
  }
}

// ============================================================
// Phase Group model
// ============================================================

class PhaseGroup {
  final String phase;
  final int iteration;
  final List<AgentEvent> events;
  final String? parallelGroup;

  const PhaseGroup({
    required this.phase,
    required this.iteration,
    required this.events,
    this.parallelGroup,
  });

  bool get isParallel => parallelGroup != null;

  Duration? get totalDuration {
    int totalMs = 0;
    bool hasDuration = false;
    for (final e in events) {
      if (e is ToolResultEvent) {
        totalMs = totalMs > e.durationMs ? totalMs : e.durationMs;
        hasDuration = true;
      }
    }
    return hasDuration ? Duration(milliseconds: totalMs) : null;
  }

  String get phaseIcon => switch (phase) {
        'planner' => '🗺️',
        'supervisor' => '🧠',
        'tools' => '🔧',
        'reflector' => '🔍',
        'respond' => '✍️',
        'system' => '⚙️',
        _ => '•',
      };

  String get phaseName => switch (phase) {
        'planner' => 'Planning',
        'supervisor' => 'Reasoning',
        'tools' => 'Tool Execution',
        'reflector' => 'Reflection',
        'respond' => 'Response',
        'system' => 'System',
        _ => phase,
      };
}

// ============================================================
// Phase group card
// ============================================================

class _PhaseGroupCard extends StatelessWidget {
  final PhaseGroup group;

  const _PhaseGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase header
          _buildPhaseHeader(),

          // Events
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: group.events.map((e) => _EventTile(event: e)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader() {
    final duration = group.totalDuration;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _phaseColor().withValues(alpha: 0.08),
        border: Border.all(
          color: _phaseColor().withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Text(group.phaseIcon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            group.phaseName,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: _phaseColor(),
            ),
          ),
          if (group.iteration > 0) ...[
            const SizedBox(width: 4),
            Text(
              '· iter ${group.iteration}',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
          ],
          if (group.isParallel) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, size: 9, color: AppColors.success),
                  const SizedBox(width: 2),
                  Text(
                    '${group.events.whereType<ToolCallEvent>().length}x parallel',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (duration != null)
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 11,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 2),
                Text(
                  '${duration.inMilliseconds}ms',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _phaseColor() => switch (group.phase) {
        'planner' => AppColors.accentBlue,
        'supervisor' => AppColors.primary,
        'tools' => AppColors.success,
        'reflector' => AppColors.warning,
        'respond' => AppColors.accentBlue,
        'system' => AppColors.textHint,
        _ => AppColors.textHint,
      };
}

// ============================================================
// Single event tile
// ============================================================

class _EventTile extends StatelessWidget {
  final AgentEvent event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          SizedBox(
            width: 16,
            child: Text(event.icon, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 4),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.summary,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.detail.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    event.detail,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Special rendering per event type
                if (event is PlanGeneratedEvent)
                  _buildPlanStepsPreview(event as PlanGeneratedEvent)
                else if (event is ReflectionEvent)
                  _buildReflectionPreview(event as ReflectionEvent)
                else if (event is ToolCallEvent &&
                    (event as ToolCallEvent).isParallel)
                  _buildParallelBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanStepsPreview(PlanGeneratedEvent e) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: e.steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(step.toolIcon, style: const TextStyle(fontSize: 9)),
                const SizedBox(width: 3),
                Text(
                  'Step ${step.stepId}: ${step.description}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (step.isParallelEligible && step.tool != 'respond') ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.call_split,
                    size: 8,
                    color: AppColors.accentBlue.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReflectionPreview(ReflectionEvent e) {
    final qualityColor = e.data.qualityScore >= 0.8
        ? AppColors.success
        : e.data.qualityScore >= 0.6
            ? AppColors.accentBlue
            : e.data.qualityScore >= 0.4
                ? AppColors.warning
                : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Quality bar
              Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: e.data.qualityScore.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: qualityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.data.qualityPercent,
                style: TextStyle(
                  fontSize: 9,
                  color: qualityColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: (e.data.needsIteration
                          ? AppColors.warning
                          : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  e.data.nextAction,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: e.data.needsIteration
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          if (e.data.missingAspects.isNotEmpty) ...[
            const SizedBox(height: 2),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: e.data.missingAspects.map((m) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    m,
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.error,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParallelBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on, size: 8, color: AppColors.success),
          const SizedBox(width: 2),
          Text(
            'parallel',
            style: TextStyle(
              fontSize: 8,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Phase chip & connector (timeline)
// ============================================================

class _PhaseChip extends StatelessWidget {
  final String phase;
  final String status; // pending | active | done | error

  const _PhaseChip({required this.phase, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final icon = _phaseIcon(phase);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            _phaseLabel(phase),
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (status == 'active') ...[
            const SizedBox(width: 3),
            SizedBox(
              width: 6,
              height: 6,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'pending' => AppColors.textHint,
        'active' => AppColors.accentBlue,
        'done' => AppColors.success,
        'error' => AppColors.error,
        _ => AppColors.textHint,
      };

  String _phaseIcon(String phase) => switch (phase) {
        'planner' => '🗺️',
        'supervisor' => '🧠',
        'tools' => '🔧',
        'reflector' => '🔍',
        'respond' => '✍️',
        _ => '•',
      };

  String _phaseLabel(String phase) => switch (phase) {
        'planner' => 'Plan',
        'supervisor' => 'Think',
        'tools' => 'Act',
        'reflector' => 'Check',
        'respond' => 'Answer',
        _ => phase,
      };
}

class _PhaseConnector extends StatelessWidget {
  final String status;

  const _PhaseConnector({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'done' ? AppColors.success : AppColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: LinearProgressIndicator(
        value: status == 'done' ? 1 : (status == 'active' ? null : 0),
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(color),
        minHeight: 2,
      ),
    );
  }
}