import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../chat/providers/chat_viewmodel.dart';
import 'providers/analysis_viewmodel.dart';
import 'widgets/action_item.dart';
import 'widgets/distribution_card.dart';
import 'widgets/empty_analysis.dart';
import 'widgets/history_item.dart';
import 'widgets/improvement_card.dart';
import 'widgets/progress_comparison_card.dart';
import 'widgets/shimmer_loading.dart';
import 'widgets/strength_card.dart';

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
            if (!data.hasData) return const EmptyAnalysis();
            return _AnalysisContent(data: data, ref: ref);
          },
          loading: () => const ShimmerLoading(),
          error: (e, _) => ErrorState(message: e.toString()),
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
          const Text('Distribusi Prediksi', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.xs),
          Text('Berdasarkan model Deep MLP terbaru',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          DistributionCard(latest: data.latest!),
          const SizedBox(height: AppSpacing.xl),
          StrengthCard(text: data.strength),
          const SizedBox(height: AppSpacing.md),
          ImprovementCard(text: data.improvement),
          const SizedBox(height: AppSpacing.xl),
          const Text('Rekomendasi Aksi', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          ...data.recommendations.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ActionItem(
                  recommendation: r,
                  onTap: () {
                    if (r.actionType == 'chat') {
                      _navigateToChat(r.actionPayload);
                    } else if (r.actionType == 'quiz') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fitur latihan segera hadir')),
                      );
                    }
                  },
                ),
              )),
          const SizedBox(height: AppSpacing.xl),
          const Text('Progress Prediksi', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          ProgressComparisonCard(comparison: data.progressComparison),
          const SizedBox(height: AppSpacing.xl),
          const Text('Riwayat Prediksi', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          ...data.historyItems.map((item) => HistoryItem(item: item)),
        ],
      ),
    );
  }
}
