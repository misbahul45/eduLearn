import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/prediction_providers.dart';
import '../../core/models/prediction.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final latestAsync = ref.watch(latestPredictionProvider);
    final historyAsync = ref.watch(predictionHistory7dProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentUserProvider);
        ref.invalidate(latestPredictionProvider);
        ref.invalidate(predictionHistory7dProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            userAsync.when(
              data: (status) => _GreetingCard(userName: status.user?.name ?? ''),
              loading: () => const _GreetingCard(userName: ''),
              error: (_, _) => const _GreetingCard(userName: ''),
            ),
            const SizedBox(height: AppSpacing.lg),

            latestAsync.when(
              data: (pred) {
                if (pred == null || pred.predictedLabel == '-' || pred.predictedLabel.isEmpty) {
                  return _EmptyPredictionCard();
                }
                return _PredictionSummaryCard(prediction: pred);
              },
              loading: () => const _ShimmerCard(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            latestAsync.when(
              data: (pred) {
                if (pred == null || pred.predictedLabel == '-' || pred.predictedLabel.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _InsightCard(prediction: pred);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            const Text('Riwayat Aktivitas', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),

            historyAsync.when(
              data: (history) => _HistoryChart(history: history),
              loading: () => const _ShimmerCard(height: 240),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),

            _QuickActionsRow(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final String userName;

  const _GreetingCard({required this.userName});

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Text(
                _initials(userName),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $userName! 👋',
                  style: AppTextStyles.h2,
                ),
                const Text(
                  'Yuk lanjut belajar hari ini',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionSummaryCard extends StatelessWidget {
  final Prediction prediction;

  const _PredictionSummaryCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final passed = prediction.isPassed;
    return Card(
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prediksi Kelulusan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    prediction.predictedLabel,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  Text(
                    'Confidence ${(prediction.confidence * 100).toStringAsFixed(0)}% · Model: Deep MLP',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              passed ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 48,
              color: AppColors.textOnPrimary.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Prediction prediction;

  const _InsightCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final passed = prediction.isPassed;
    return Card(
      color: passed
          ? AppColors.success.withValues(alpha: 0.1)
          : AppColors.warning.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_rounded,
              color: passed ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                passed
                    ? 'Kerja bagus! Pertahankan ritme belajar 30 menit/hari.'
                    : 'Perbanyak quiz score dan latihan soal untuk meningkatkan prediksi.',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPredictionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Belum ada prediksi',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Mulai chat dengan AI untuk dapatkan prediksi kelulusanmu.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutes.chatTab),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18),
              label: const Text('Tanya AI'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<Prediction> history;

  const _HistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Text('Belum ada riwayat', style: AppTextStyles.caption),
          ),
        ),
      );
    }

    final sorted = List<Prediction>.from(history)
      ..sort((a, b) => a.generatedAt.compareTo(b.generatedAt));

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.confidence);
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (value) {
                      if (value == 0.5) {
                        return FlLine(
                          color: AppColors.textHint.withValues(alpha: 0.5),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        );
                      }
                      return FlLine(
                        color: AppColors.border,
                        strokeWidth: 0.5,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).toInt()}%',
                            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: spots.length > 1,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                          final date = sorted[idx].generatedAt;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 1,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: spots.length <= 14,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.primary,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${(spot.y * 100).toStringAsFixed(0)}%',
                            const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Probabilitas Lulus', style: AppTextStyles.caption),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 1,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        border: Border.all(color: AppColors.textHint, width: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Threshold (0.5)', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.chat_bubble_rounded,
          label: 'Tanya AI',
          onTap: () => context.goNamed(AppRoutes.chatTab),
        ),
        _QuickAction(
          icon: Icons.insights_rounded,
          label: 'Analisis',
          onTap: () => context.goNamed(AppRoutes.analysisTab),
        ),
        _QuickAction(
          icon: Icons.quiz_rounded,
          label: 'Latihan',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur latihan akan segera hadir')),
            );
          },
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;

  const _ShimmerCard({this.height = 120});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
