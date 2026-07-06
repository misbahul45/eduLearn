import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ReasoningCard extends StatefulWidget {
  final String text;
  final String title;
  final IconData icon;
  final Color accentColor;
  final bool initiallyExpanded;
  final bool isStreaming;

  const ReasoningCard({
    super.key,
    required this.text,
    this.title = 'Proses Berpikir AI',
    this.icon = Icons.psychology_outlined,
    this.accentColor = AppColors.primary,
    this.initiallyExpanded = false,
    this.isStreaming = false,
  });

  @override
  State<ReasoningCard> createState() => _ReasoningCardState();
}

class _ReasoningCardState extends State<ReasoningCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded || widget.isStreaming;
  }

  @override
  void didUpdateWidget(ReasoningCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      _expanded = true;
    }
    if (!widget.isStreaming && oldWidget.isStreaming && _expanded) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _expanded = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.04),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              color: widget.accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.icon,
                          size: 14,
                          color: widget.accentColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: AppTextStyles.caption.copyWith(
                              color: widget.accentColor.withValues(alpha: 0.85),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isStreaming) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: widget.accentColor,
                            ),
                          ),
                        ],
                        const Spacer(),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.expand_more,
                            size: 16,
                            color: AppColors.textHint.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topLeft,
                  clipBehavior: Clip.none,
                  child: _expanded && widget.text.isNotEmpty
                      ? _buildContent()
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          color: widget.accentColor.withValues(alpha: 0.15),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: MarkdownBody(
            data: widget.text,
            shrinkWrap: true,
            styleSheet: MarkdownStyleSheet(
              p: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              listBullet: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.75),
              ),
              strong: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
              em: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              h1: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              h2: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              h3: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              code: AppTextStyles.caption.copyWith(
                color: widget.accentColor.withValues(alpha: 0.9),
                fontFamily: 'monospace',
                fontSize: 11,
                backgroundColor: widget.accentColor.withValues(alpha: 0.08),
              ),
              codeblockDecoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.1),
                ),
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: widget.accentColor.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
              ),
              blockquotePadding:
                  const EdgeInsets.only(left: 12, top: 4, bottom: 4, right: 4),
            ),
            selectable: true,
          ),
        ),
      ],
    );
  }
}