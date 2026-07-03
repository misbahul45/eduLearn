import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class BiodataCard extends StatelessWidget {
  final dynamic user;

  const BiodataCard({
    super.key,
    required this.user,
  });

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
            BioRow(
              icon: Icons.person_outline,
              label: 'Nama',
              value: user?.name ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            BioRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user?.email ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            BioRow(
              icon: Icons.school_outlined,
              label: 'Peran',
              value: user?.roleLabel ?? '-',
            ),
            const Divider(height: AppSpacing.lg),
            BioRow(
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

class BioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const BioRow({
    super.key,
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
