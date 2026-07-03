import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/prediction.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../chat/providers/chat_viewmodel.dart';
import 'providers/analysis_viewmodel.dart';

class AnalysisPage extends ConsumerWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(analysisViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text('Analisis', style: AppTextStyles.h2),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(analysisViewModelProvider.future),
        child: analysisAsync.when(
          data: (data) {
            if (!data.hasData) return const _EmptyAnalysis();
            return _AnalysisContent(data: data, ref: ref);
          },
          loading: () => const _ShimmerLoading(),
          error: (e, _) => _ErrorState(message: e.toString()),
        ),
      ),
    );
  }
}

class _AnalysisContent extends StatelessWidget {
  final AnalysisData data;
  final WidgetRef ref;

  const _AnalysisContent({required this.data, required this.ref});

  void _navigateToChat(String query) {
    ref.read(chatPresetQueryProvider.notifier).state = query;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('Distribusi Prediksi', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.xs),
        Text('Berdasarkan model Deep MLP terbaru', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        _DistributionCard(latest: data.latest!),
        const SizedBox(height: AppSpacing.xl),
        _StrengthCard(text: data.strength),
        const SizedBox(height: AppSpacing.md),
        _ImprovementCard(text: data.improvement),
        const SizedBox(height: AppSpacing.xl),
        Text('Rekomendasi Aksi', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        ...data.recommendations.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ActionItem(
            recommendation: r,
            onTap: () {
              if (r.actionType == 'chat') {
                _navigateToChat(r.actionPayload);
              } else if (r.actionType == 'quiz') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur latihan segera hadir')),
                );
              }
            },
          ),
        )),
        const SizedBox(height: AppSpacing.xl),
        Text('Progress Prediksi', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        _ProgressComparisonCard(comparison: data.progressComparison),
        const SizedBox(height: AppSpacing.xl),
        Text('Riwayat Prediksi', style: AppTextStyles.h2),
        const SizedBox(height: AppSpacing.md),
        ...data.historyItems.map((item) => _HistoryItem(item: item)),
      ],
    ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final Prediction latest;

  const _DistributionCard({required this.latest});

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
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
                      Text(centerValue, style: AppTextStyles.h1.copyWith(fontSize: 28)),
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
                  _LegendRow(color: AppColors.success, label: 'Lulus', value: '${(passedPct * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: AppSpacing.sm),
                  _LegendRow(color: AppColors.error, label: 'Tidak Lulus', value: '${(failedPct * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        Text(value, style: AppTextStyles.subtitle),
      ],
    );
  }
}

class _StrengthCard extends StatelessWidget {
  final String text;

  const _StrengthCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Text('Kekuatan', style: AppTextStyles.subtitle.copyWith(color: AppColors.success)),
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

class _ImprovementCard extends StatelessWidget {
  final String text;

  const _ImprovementCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Text('Area Perbaikan', style: AppTextStyles.subtitle.copyWith(color: AppColors.warning)),
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

class _ActionItem extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback onTap;

  const _ActionItem({required this.recommendation, required this.onTap});

  IconData _icon() {
    switch (recommendation.icon) {
      case IconType.chat:
        return Icons.chat_rounded;
      case IconType.book:
        return Icons.menu_book_rounded;
      case IconType.quiz:
        return Icons.quiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(_icon(), color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recommendation.title, style: AppTextStyles.label),
                    const SizedBox(height: 2),
                    Text(recommendation.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressComparisonCard extends StatelessWidget {
  final ProgressComparison? comparison;

  const _ProgressComparisonCard({this.comparison});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: comparison == null
            ? Center(
                child: Text('Belum cukup data untuk perbandingan', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Probabilitas kemarin', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          Text('${(comparison!.yesterdayProbability * 100).toStringAsFixed(0)}%', style: AppTextStyles.h1),
                        ],
                      ),
                      Icon(
                        comparison!.delta > 0
                            ? Icons.trending_up_rounded
                            : comparison!.delta < 0
                                ? Icons.trending_down_rounded
                                : Icons.remove_rounded,
                        color: comparison!.delta > 0
                            ? AppColors.success
                            : comparison!.delta < 0
                                ? AppColors.error
                                : AppColors.textSecondary,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Probabilitas hari ini', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          Text(
                            '${(comparison!.todayProbability * 100).toStringAsFixed(0)}%',
                            style: AppTextStyles.h1.copyWith(
                              color: comparison!.delta > 0 ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: comparison!.todayProbability,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(
                        comparison!.todayProbability >= 0.5 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    comparison!.delta > 0
                        ? 'Naik ${(comparison!.delta * 100).toStringAsFixed(1)}%'
                        : comparison!.delta < 0
                            ? 'Turun ${(comparison!.delta.abs() * 100).toStringAsFixed(1)}%'
                            : 'Tidak ada perubahan',
                    style: AppTextStyles.caption.copyWith(
                      color: comparison!.delta > 0
                          ? AppColors.success
                          : comparison!.delta < 0
                              ? AppColors.error
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final PredictionHistoryItem item;

  const _HistoryItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final passed = item.probability >= 0.5;
    final color = passed ? AppColors.success : AppColors.error;
    final label = passed ? 'Lulus' : 'Tidak Lulus';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dateStr = '${item.date.day} ${months[item.date.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Text(dateStr, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500, color: color)),
              ),
              Text('${(item.probability * 100).toStringAsFixed(0)}%', style: AppTextStyles.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            const Text('Belum ada data analisis', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mulai chat dengan AI untuk dapatkan prediksi pertamamu.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.go('/home/chat'),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Tanya AI'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            const Text('Gagal memuat data', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(width: 200, height: 20, decoration: _shimmer()),
        const SizedBox(height: AppSpacing.md),
        Container(height: 180, decoration: _shimmer(boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
        const SizedBox(height: AppSpacing.xl),
        Container(height: 200, decoration: _shimmer(boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 200, decoration: _shimmer(boxShape: BoxShape.rectangle, borderRadius: AppRadius.lg)),
      ],
    );
  }

  BoxDecoration _shimmer({BoxShape boxShape = BoxShape.rectangle, double borderRadius = 0}) {
    return BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.5),
      borderRadius: boxShape == BoxShape.rectangle ? BorderRadius.circular(borderRadius) : null,
      shape: boxShape,
    );
  }
}
