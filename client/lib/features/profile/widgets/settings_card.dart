import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
          ),
          Divider(height: 1, indent: AppSpacing.lg),
          SettingTile(
            icon: Icons.language_rounded,
            title: 'Bahasa',
            subtitle: 'Indonesia',
          ),
          Divider(height: 1, indent: AppSpacing.lg),
          SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema',
            subtitle: 'Terang',
          ),
          Divider(height: 1, indent: AppSpacing.lg),
          SettingTile(icon: Icons.help_outline, title: 'Bantuan'),
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const SettingTile({
    super.key,
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
