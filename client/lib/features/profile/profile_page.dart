import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/providers/knowledge_providers.dart';
import '../../core/providers/users_providers.dart';
import '../../core/routing/app_routes.dart';
import '../../core/services/knowledge_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'knowledge_upload_sheet.dart';

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
              data: (status) => _ProfileHeader(user: status.user),
              loading: () => const _AvatarShimmer(),
              error: (_, _) => const _AvatarShimmer(),
            ),
            const SizedBox(height: AppSpacing.xl),
            userAsync.when(
              data: (status) => _BiodataCard(user: status.user),
              loading: () => const _CardShimmer(),
              error: (_, _) => const _CardShimmer(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Statistik', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.md),
            statsAsync.when(
              data: (stats) => _StatsRow(
                totalConversations: stats?.totalConversations ?? 0,
                totalPredictions: stats?.totalPredictions ?? 0,
                avgScore: stats?.avgPredictionScore ?? 0.0,
              ),
              loading: () => const _StatsShimmer(),
              error: (_, _) => const _StatsShimmer(),
            ),
            userAsync.when(
              data: (status) {
                final user = status.user;
                if (user != null && user.isPengajar) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      _KnowledgeManagementSection(),
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
            const _SettingsCard(),
            const SizedBox(height: AppSpacing.xl),
            const _LogoutButton(),
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

class _ProfileHeader extends StatelessWidget {
  final dynamic user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary,
            child: Text(
              user?.initials ?? 'U',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user?.name ?? 'User', style: AppTextStyles.h1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            user?.email ?? '',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (user != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.isPengajar
                    ? AppColors.accentBlue.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                user.roleLabel,
                style: AppTextStyles.caption.copyWith(
                  color: user.isPengajar
                      ? AppColors.accentBlue
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BiodataCard extends StatelessWidget {
  final dynamic user;

  const _BiodataCard({required this.user});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Biodata', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.md),
            _BioRow(
              icon: Icons.person_outline,
              label: 'Nama',
              value: user?.name ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            _BioRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            _BioRow(
              icon: Icons.school_outlined,
              label: 'Peran',
              value: user?.roleLabel ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            _BioRow(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung',
              value: _formatDate(user?.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _BioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BioRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalConversations;
  final int totalPredictions;
  final double avgScore;

  const _StatsRow({
    required this.totalConversations,
    required this.totalPredictions,
    required this.avgScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Percakapan',
            value: '$totalConversations',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.insights_rounded,
            label: 'Prediksi',
            value: '$totalPredictions',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.star_border_rounded,
            label: 'Rata-rata Lulus',
            value: '${(avgScore * 100).toInt()}%',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: AppTextStyles.h2),
            Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeManagementSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(knowledgeDocumentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Materi Knowledge Base', style: AppTextStyles.h2),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Upload'),
              onPressed: () => _showUploadSheet(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        docsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return _EmptyKnowledge(
                message:
                    'Belum ada materi. Upload file PDF/DOCX/TXT/MD untuk mulai.',
                onUpload: () => _showUploadSheet(context),
              );
            }
            return Column(
              children: docs
                  .map((doc) => _KnowledgeDocItem(doc: doc))
                  .toList(),
            );
          },
          loading: () => const _KnowledgeSkeleton(),
          error: (e, _) => Center(
            child: Text(
              'Gagal memuat: $e',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => const KnowledgeUploadSheet(),
    );
  }
}

class _EmptyKnowledge extends StatelessWidget {
  final String message;
  final VoidCallback onUpload;

  const _EmptyKnowledge({
    required this.message,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KnowledgeDocItem extends ConsumerWidget {
  final KnowledgeDocument doc;

  const _KnowledgeDocItem({required this.doc});

  IconData _fileIcon() {
    if (doc.fileName.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (doc.fileName.endsWith('.docx')) return Icons.description_rounded;
    if (doc.fileName.endsWith('.md')) return Icons.code_rounded;
    return Icons.text_snippet_rounded;
  }

  Color _statusColor() {
    return switch (doc.status) {
      'ready' => AppColors.success,
      'processing' => AppColors.warning,
      'failed' => AppColors.error,
      _ => AppColors.textHint,
    };
  }

  String _statusLabel() {
    return switch (doc.status) {
      'ready' => 'Siap',
      'processing' => 'Diproses',
      'failed' => 'Gagal',
      _ => doc.status,
    };
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus materi'),
        content: const Text(
          'Hapus materi ini? Siswa tidak akan bisa akses referensi lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(knowledgeServiceProvider)
                    .deleteDocument(doc.documentId);
                ref.invalidate(knowledgeDocumentsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Materi berhasil dihapus'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal menghapus materi'),
                    ),
                  );
                }
              }
            },
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: Icon(_fileIcon(), color: AppColors.accentBlue),
          title: Text(
            doc.title.isNotEmpty ? doc.title : doc.fileName,
            style: AppTextStyles.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${doc.totalChunks} chunks · '
            '${doc.fileSizeBytes > 1024 ? '${(doc.fileSizeBytes / 1024).toStringAsFixed(0)} KB' : '${doc.fileSizeBytes} B'}',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  _statusLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(context, ref);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: doc.status == 'failed' && doc.errorMessage != null
              ? () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Error',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            doc.errorMessage!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
          ),
          const Divider(height: 1, indent: AppSpacing.lg),
          _SettingTile(
            icon: Icons.language_rounded,
            title: 'Bahasa',
            subtitle: 'Indonesia',
          ),
          const Divider(height: 1, indent: AppSpacing.lg),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema',
            subtitle: 'Terang',
          ),
          const Divider(height: 1, indent: AppSpacing.lg),
          _SettingTile(icon: Icons.help_outline, title: 'Bantuan'),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTextStyles.body),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption)
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
        size: 20,
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan ini akan tersedia segera'),
          ),
        );
      },
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _showLogoutDialog(context, ref),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Keluar'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          foregroundColor: AppColors.error,
          padding:
              const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yakin ingin keluar?'),
        content: const Text('Kamu akan kembali ke halaman login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(currentUserProvider);
              if (context.mounted) {
                context.goNamed(AppRoutes.login);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _AvatarShimmer extends StatelessWidget {
  const _AvatarShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.black12,
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnowledgeSkeleton extends StatelessWidget {
  const _KnowledgeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            elevation: 0,
            child: ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
              ),
              title: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
              ),
              subtitle: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
