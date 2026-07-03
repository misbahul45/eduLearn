import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/prediction_providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/greeting_card.dart';
import 'widgets/history_chart.dart';
import 'widgets/prediction_summary_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/shimmer_card.dart';

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
              data: (status) => GreetingCard(userName: status.user?.name ?? ''),
              loading: () => const GreetingCard(userName: ''),
              error: (_, _) => const GreetingCard(userName: ''),
            ),
            const SizedBox(height: AppSpacing.lg),
            latestAsync.when(
              data: (pred) {
                if (pred == null ||
                    pred.predictedLabel == '-' ||
                    pred.predictedLabel.isEmpty) {
                  return const EmptyPredictionCard();
                }
                return PredictionSummaryCard(prediction: pred);
              },
              loading: () => const ShimmerCard(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            latestAsync.when(
              data: (pred) {
                if (pred == null ||
                    pred.predictedLabel == '-' ||
                    pred.predictedLabel.isEmpty) {
                  return const SizedBox.shrink();
                }
                return InsightCard(prediction: pred);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Riwayat Aktivitas', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            historyAsync.when(
              data: (history) => HistoryChart(history: history),
              loading: () => const ShimmerCard(height: 240),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
