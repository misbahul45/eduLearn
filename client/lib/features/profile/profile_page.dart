import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/knowledge_providers.dart';
import '../../core/providers/users_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/biodata_card.dart';
import 'widgets/knowledge_management_section.dart';
import 'widgets/logout_button.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_shimmers.dart';
import 'widgets/settings_card.dart';
import 'widgets/stats_row.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: const Text('Profil', style: AppTextStyles.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan ini akan tersedia segera'),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentUserProvider);
          ref.invalidate(userStatsProvider);
          ref.invalidate(knowledgeDocumentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            userAsync.when(
              data: (status) => ProfileHeader(user: status.user),
              loading: () => const AvatarShimmer(),
              error: (_, _) => const AvatarShimmer(),
            ),
            const SizedBox(height: AppSpacing.xl),
            userAsync.when(
              data: (status) => BiodataCard(user: status.user),
              loading: () => const CardShimmer(),
              error: (_, _) => const CardShimmer(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Statistik', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            statsAsync.when(
              data: (stats) => StatsRow(
                totalConversations: stats?.totalConversations ?? 0,
                totalPredictions: stats?.totalPredictions ?? 0,
                avgScore: stats?.avgPredictionScore ?? 0.0,
              ),
              loading: () => const StatsShimmer(),
              error: (_, _) => const StatsShimmer(),
            ),
            userAsync.when(
              data: (status) {
                final user = status.user;
                if (user != null && user.isPengajar) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.xl),
                      KnowledgeManagementSection(),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Pengaturan', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            const SettingsCard(),
            const SizedBox(height: AppSpacing.xl),
            const LogoutButton(),
            const SizedBox(height: AppSpacing.md),
            const Center(
              child: Text('EduLearn AI v1.0.0', style: AppTextStyles.caption),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
