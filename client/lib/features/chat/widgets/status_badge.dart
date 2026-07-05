import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/chat_state.dart';
import '../../../../core/services/agent_socket_service.dart';

class StatusBadge extends StatelessWidget {
  final AgentStatus status;
  final ConnectionMode connectionMode;

  const StatusBadge({
    super.key,
    required this.status,
    required this.connectionMode,
  });

  (IconData, Color, String, bool) _resolve() {
    if (connectionMode == ConnectionMode.rest) {
      return (
        Icons.warning_amber_rounded,
        AppColors.warning,
        'Mode terbatas — koneksi real-time terputus',
        false,
      );
    }

    return switch (status) {
      AgentStatus.thinking => (
          Icons.more_horiz_rounded,
          AppColors.primary,
          'AI sedang memproses...',
          true,
        ),
      _ => (
          Icons.check_circle_rounded,
          AppColors.success,
          'Terhubung — real-time',
          false,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip, isLoading) = _resolve();

    return Tooltip(
      message: tooltip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Container(
          key: ValueKey('$connectionMode-$status'),
          width: 22,
          height: 22,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: isLoading
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                )
              : Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}