import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'citation_tile.dart';
import 'prediction_chart_card.dart';
import 'web_search_tile.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _Avatar(isUser: false),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.7),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    border: isUser ? null : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.lg),
                      topRight: const Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.sm),
                      bottomRight: Radius.circular(isUser ? AppRadius.sm : AppRadius.lg),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BubbleContent(message: widget.message),
                      if (widget.message.prediction != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        PredictionChartCard(prediction: widget.message.prediction!),
                      ],
                      if (widget.message.citations.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        CitationTile(citations: widget.message.citations),
                      ],
                      if (widget.message.webResults.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        WebSearchTile(results: widget.message.webResults),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: AppSpacing.sm),
                _Avatar(isUser: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    final base = isUser ? AppColors.accentBlue : AppColors.primary;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, base.withValues(alpha: 0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
        size: 18,
        color: AppColors.textOnPrimary,
      ),
    );
  }
}

class BubbleContent extends StatefulWidget {
  final ChatMessage message;

  const BubbleContent({
    super.key,
    required this.message,
  });

  @override
  State<BubbleContent> createState() => _BubbleContentState();
}

class _BubbleContentState extends State<BubbleContent> {
  bool _thinkingExpanded = false;
  late List<_ContentSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = _parseContent(widget.message.content);
  }

  @override
  void didUpdateWidget(BubbleContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.content != widget.message.content) {
      _sections = _parseContent(widget.message.content);
    }
  }

  List<_ContentSection> _parseContent(String content) {
    final sections = <_ContentSection>[];
    final thinkRegex = RegExp(r'(<think>[\s\S]*?</think>|<think>[\s\S]*$)', caseSensitive: false);
    final matches = thinkRegex.allMatches(content);

    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        final textBefore = content.substring(lastIndex, match.start).trim();
        if (textBefore.isNotEmpty) {
          sections.add(_ContentSection(
            type: ContentType.regular,
            text: textBefore,
          ));
        }
      }

      final rawThinking = match.group(0) ?? '';
      final thinkingText = rawThinking
          .replaceFirst(RegExp(r'^<think>', caseSensitive: false), '')
          .replaceFirst(RegExp(r'</think>$', caseSensitive: false), '')
          .trim();

      if (thinkingText.isNotEmpty) {
        sections.add(_ContentSection(
          type: ContentType.thinking,
          text: thinkingText,
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final remaining = content.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        sections.add(_ContentSection(
          type: ContentType.regular,
          text: remaining,
        ));
      }
    }

    if (sections.isEmpty && content.trim().isNotEmpty) {
      sections.add(_ContentSection(
        type: ContentType.regular,
        text: content.trim(),
      ));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message.content.isEmpty && widget.message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Memproses',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          const _TypingDots(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._sections.asMap().entries.map((entry) {
          final section = entry.value;

          if (section.type == ContentType.thinking) {
            return _buildThinkingSection(section.text);
          } else {
            return _buildRegularText(section.text);
          }
        }).toList(),

        if (widget.message.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 15, color: AppColors.error),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.message.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThinkingSection(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.textHint.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _thinkingExpanded = !_thinkingExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 14,
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Proses Berpikir AI',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _thinkingExpanded ? 0.5 : 0,
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
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _thinkingExpanded
                        ? Column(
                            children: [
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: MarkdownBody(
                                  data: text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                    listBullet: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                                    ),
                                    strong: AppTextStyles.caption.copyWith(
                                      color: AppColors.textPrimary.withValues(alpha: 0.75),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    em: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.65),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    h1: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.75),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    h2: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.75),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    h3: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    code: AppTextStyles.caption.copyWith(
                                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                                      fontStyle: FontStyle.italic,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: AppColors.background.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: AppColors.textHint.withValues(alpha: 0.4),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    blockquotePadding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                                  ),
                                  selectable: true,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularText(String text) {
    final displayText = widget.message.isStreaming && _sections.length == 1
        ? '$text'
        : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MarkdownBody(
        data: displayText,
        styleSheet: MarkdownStyleSheet(
          p: widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body,
          strong: (widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body).copyWith(fontWeight: FontWeight.bold),
          em: (widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body).copyWith(fontStyle: FontStyle.italic),
          h1: (widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          h2: (widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body).copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          h3: (widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body).copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          listBullet: widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body,
          code: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: widget.message.isUser
                ? AppColors.textOnPrimary
                : AppColors.primary,
            backgroundColor: widget.message.isUser
                ? AppColors.textOnPrimary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.08),
          ),
          codeblockDecoration: BoxDecoration(
            color: widget.message.isUser
                ? AppColors.textOnPrimary.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(6),
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.message.isUser
                    ? AppColors.textOnPrimary.withValues(alpha: 0.5)
                    : AppColors.primary.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
          ),
          blockquotePadding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          tableBorder: TableBorder.all(
            color: widget.message.isUser
                ? AppColors.textOnPrimary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
          tableHead: widget.message.isUser
              ? AppTextStyles.body.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                )
              : AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          tableBody: widget.message.isUser
              ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
              : AppTextStyles.body,
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: widget.message.isUser
                    ? AppColors.textOnPrimary.withValues(alpha: 0.3)
                    : AppColors.border,
                width: 1,
              ),
            ),
          ),
        ),
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href));
          }
        },
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - (i * 0.2)) % 1.0;
              final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
              return Transform.translate(
                offset: Offset(0, -4 * bounce),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.5 + bounce * 0.5),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

enum ContentType { regular, thinking }

class _ContentSection {
  final ContentType type;
  final String text;

  _ContentSection({
    required this.type,
    required this.text,
  });
}