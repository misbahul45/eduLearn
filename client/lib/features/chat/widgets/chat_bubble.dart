import 'package:flutter/material.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'citation_tile.dart';
import 'prediction_chart_card.dart';
import 'web_search_tile.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.7),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft:
                      Radius.circular(isUser ? AppRadius.lg : AppRadius.sm),
                  bottomRight:
                      Radius.circular(isUser ? AppRadius.sm : AppRadius.lg),
                ),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BubbleContent(message: message),
                  if (message.prediction != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    PredictionChartCard(prediction: message.prediction!),
                  ],
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    CitationTile(citations: message.citations),
                  ],
                  if (message.webResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    WebSearchTile(results: message.webResults),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BubbleContent extends StatelessWidget {
  final ChatMessage message;

  const BubbleContent({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message.content.isEmpty && message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Memproses', style: AppTextStyles.body),
          const SizedBox(width: 4),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          SelectableText(
            message.isStreaming
                ? '${message.content}┃'
                : message.content,
            style: message.isUser
                ? AppTextStyles.body
                    .copyWith(color: AppColors.textOnPrimary)
                : AppTextStyles.body,
          ),
        if (message.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Chip(
            label: Text(
              message.error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.1),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    );
  }
}
