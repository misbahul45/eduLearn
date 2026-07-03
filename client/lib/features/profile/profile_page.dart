import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/prediction_providers.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final analysisAsync = ref.watch(predictionAnalysisProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.md),
        userAsync.when(
          data: (status) {
            final user = status.user;
            return Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    _getInitials(user?.name ?? 'U'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(user?.name ?? 'User', style: AppTextStyles.h1),
                Text(user?.email ?? '', style: AppTextStyles.caption),
                if (user?.role == 'pengajar' || user?.role == 'admin')
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Text(
                      user!.role == 'pengajar' ? 'Pengajar' : 'Admin',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.lg),

        analysisAsync.when(
          data: (analysis) {
            if (analysis == null) return const SizedBox.shrink();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statistik Belajar', style: AppTextStyles.h2),
                    const SizedBox(height: AppSpacing.md),
                    _StatRow(label: 'Total Prediksi', value: '${analysis.totalPredictions}'),
                    _StatRow(label: 'Tingkat Kelulusan', value: '${analysis.passRate.toStringAsFixed(1)}%'),
                    _StatRow(label: 'Rata-rata Probabilitas', value: '${(analysis.avgProbability * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.md),

        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                title: const Text('Materi Pembelajaran'),
                subtitle: const Text('Kelola materi belajar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.goNamed(AppRoutes.knowledge),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppColors.accentBlue),
                title: const Text('Tentang Aplikasi'),
                subtitle: const Text('Versi 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.goNamed(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Keluar', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.length == 1 && name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
