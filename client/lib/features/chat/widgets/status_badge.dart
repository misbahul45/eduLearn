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

  @override
  Widget build(BuildContext context) {
    if (connectionMode == ConnectionMode.rest) {
      return const Icon(
        Icons.warning_amber_rounded,
        size: 16,
        color: AppColors.warning,
      );
    }
    return switch (status) {
      AgentStatus.thinking => const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      _ => const Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: AppColors.success,
        ),
    };
  }
}
