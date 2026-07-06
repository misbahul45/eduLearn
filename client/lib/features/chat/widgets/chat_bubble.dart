import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'action_group_card.dart';
import 'citation_tile.dart';
import 'plan_card.dart';
import 'prediction_chart_card.dart';
import 'reasoning_card.dart';
import 'reflection_card.dart';
import 'web_search_tile.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
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
    ).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic),
    );
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
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const _Avatar(isUser: false),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width *
                        (isUser ? 0.75 : 0.72),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.border.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(AppRadius.lg),
                      topRight: const Radius.circular(AppRadius.lg),
                      bottomLeft: Radius.circular(
                          isUser ? AppRadius.lg : AppRadius.sm),
                      bottomRight: Radius.circular(
                          isUser ? AppRadius.sm : AppRadius.lg),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isUser ? 0.08 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BubbleContent(message: widget.message),
                      // Parallel tool groups (NEW)
                      if (widget.message.parallelGroups != null &&
                          widget.message.parallelGroups!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        ...widget.message.parallelGroups!.map(
                          (group) => ActionGroupCard(group: group),
                        ),
                      ],
                      if (widget.message.prediction != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        PredictionChartCard(
                            prediction: widget.message.prediction!),
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
                const _Avatar(isUser: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Avatar (tidak berubah)
// ============================================================

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

// ============================================================
// Bubble Content — multi-tag parser
// ============================================================

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

  /// Multi-tag parser: <plan>, <reasoning>/<think>, <action>, <reflection>
  List<_ContentSection> _parseContent(String content) {
    final sections = <_ContentSection>[];

    // Regex untuk semua tag: plan, reasoning, think, action, reflection
    // Format: <tag attr="val">content</tag>
    // Untuk streaming: handle unclosed <think> dan <reasoning>
    final tagRegex = RegExp(
      r'<(plan|reasoning|think|action|reflection)([^>]*)>([\s\S]*?)</\1>',
      caseSensitive: false,
    );

    final matches = tagRegex.allMatches(content);
    int lastIndex = 0;

    for (final match in matches) {
      // Text sebelum tag
      if (match.start > lastIndex) {
        final textBefore = content.substring(lastIndex, match.start).trim();
        if (textBefore.isNotEmpty) {
          sections.add(_ContentSection(
            type: ContentType.regular,
            text: textBefore,
          ));
        }
      }

      final tag = match.group(1)!.toLowerCase();
      final attrs = match.group(2) ?? '';
      final text = match.group(3)?.trim() ?? '';

      if (text.isNotEmpty) {
        sections.add(_ContentSection(
          type: _mapTagToType(tag),
          text: text,
          metadata: _extractMetadata(tag, attrs),
        ));
      }

      lastIndex = match.end;
    }

    // Handle unclosed tags (streaming in-progress)
    if (lastIndex < content.length) {
      final remaining = content.substring(lastIndex);

      // Check for unclosed <think> or <reasoning>
      final unclosedRegex = RegExp(
        r'<(plan|reasoning|think|action|reflection)([^>]*)>([\s\S]*)$',
        caseSensitive: false,
      );
      final unclosedMatch = unclosedRegex.firstMatch(remaining);

      if (unclosedMatch != null) {
        // Text before unclosed tag
        final beforeTag = remaining.substring(0, unclosedMatch.start).trim();
        if (beforeTag.isNotEmpty) {
          sections.add(_ContentSection(
            type: ContentType.regular,
            text: beforeTag,
          ));
        }

        // The unclosed tag content (streaming)
        final tag = unclosedMatch.group(1)!.toLowerCase();
        final attrs = unclosedMatch.group(2) ?? '';
        final text = unclosedMatch.group(3)?.trim() ?? '';

        if (text.isNotEmpty) {
          sections.add(_ContentSection(
            type: _mapTagToType(tag),
            text: text,
            metadata: _extractMetadata(tag, attrs),
            isStreaming: true,
          ));
        }
      } else {
        final trimmed = remaining.trim();
        if (trimmed.isNotEmpty) {
          sections.add(_ContentSection(
            type: ContentType.regular,
            text: trimmed,
          ));
        }
      }
    }

    // Fallback: jika content tidak kosong tapi tidak ada section
    if (sections.isEmpty && content.trim().isNotEmpty) {
      sections.add(_ContentSection(
        type: ContentType.regular,
        text: content.trim(),
      ));
    }

    return sections;
  }

  ContentType _mapTagToType(String tag) => switch (tag) {
        'plan' => ContentType.plan,
        'reasoning' => ContentType.reasoning,
        'think' => ContentType.reasoning, // backward compat
        'action' => ContentType.action,
        'reflection' => ContentType.reflection,
        _ => ContentType.regular,
      };

  Map<String, dynamic> _extractMetadata(String tag, String attrs) {
    final meta = <String, dynamic>{};

    // Extract quality="0.85"
    final qualityMatch = RegExp(r'quality="([\d.]+)"').firstMatch(attrs);
    if (qualityMatch != null) {
      meta['quality'] = double.tryParse(qualityMatch.group(1)!) ?? 0.0;
    }

    // Extract missing="..."
    final missingMatch = RegExp(r'missing="([^"]*)"').firstMatch(attrs);
    if (missingMatch != null) {
      meta['missing'] = missingMatch.group(1) ?? '';
    }

    // Extract group="iter_2_n3"
    final groupMatch = RegExp(r'group="([^"]*)"').firstMatch(attrs);
    if (groupMatch != null) {
      meta['parallel_group'] = groupMatch.group(1);
    }

    // Extract reasoning="..." (untuk plan)
    final reasoningMatch = RegExp(r'reasoning="([^"]*)"').firstMatch(attrs);
    if (reasoningMatch != null) {
      meta['reasoning'] = reasoningMatch.group(1) ?? '';
    }

    return meta;
  }

  @override
  Widget build(BuildContext context) {
    // Empty + streaming → typing indicator
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
        // Render each section
        ..._sections.map((section) => _buildSection(section)),

        // Error display
        if (widget.message.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ErrorBanner(error: widget.message.error!),
        ],
      ],
    );
  }

  Widget _buildSection(_ContentSection section) {
    return switch (section.type) {
      ContentType.plan => _buildPlanSection(section),
      ContentType.reasoning => _buildReasoningSection(section),
      ContentType.action => _buildActionSection(section),
      ContentType.reflection => _buildReflectionSection(section),
      ContentType.regular => _buildRegularText(section.text),
    };
  }

  // ============================================================
  // Plan section
  // ============================================================

  Widget _buildPlanSection(_ContentSection section) {
    // Jika ChatMessage punya planSteps, gunakan itu (lebih reliable)
    // Jika tidak, parse dari text (fallback)
    final planSteps = widget.message.planSteps;
    if (planSteps != null && planSteps.isNotEmpty) {
      return PlanCard(
        steps: planSteps,
        reasoning: section.metadata?['reasoning'] as String? ?? '',
      );
    }

    // Fallback: render plan text sebagai reasoning-style card
    return ReasoningCard(
      text: section.text,
      title: 'Execution Plan',
      icon: Icons.map_outlined,
      accentColor: AppColors.accentBlue,
      isStreaming: section.isStreaming,
    );
  }

  // ============================================================
  // Reasoning section (think tag)
  // ============================================================

  Widget _buildReasoningSection(_ContentSection section) {
    return ReasoningCard(
      text: section.text,
      title: 'Proses Berpikir AI',
      icon: Icons.psychology_outlined,
      accentColor: AppColors.primary,
      isStreaming: section.isStreaming,
    );
  }

  // ============================================================
  // Action section (tool call narrative)
  // ============================================================

  Widget _buildActionSection(_ContentSection section) {
    final parallelGroup = section.metadata?['parallel_group'] as String?;
    final isParallel = parallelGroup != null;

    return ReasoningCard(
      text: section.text,
      title: isParallel ? 'Action (Parallel)' : 'Action',
      icon: isParallel ? Icons.flash_on : Icons.play_arrow,
      accentColor: AppColors.success,
      isStreaming: section.isStreaming,
    );
  }

  // ============================================================
  // Reflection section
  // ============================================================

  Widget _buildReflectionSection(_ContentSection section) {
    // Jika ChatMessage punya reflection data, gunakan itu
    final reflectionData = widget.message.reflection;
    if (reflectionData != null) {
      return ReflectionCard(data: reflectionData);
    }

    // Fallback: parse dari tag attributes + text
    return _FallbackReflectionCard(
      text: section.text,
      quality: section.metadata?['quality'] as double?,
      missing: section.metadata?['missing'] as String? ?? '',
      isStreaming: section.isStreaming,
    );
  }

  // ============================================================
  // Regular text (Markdown)
  // ============================================================

  Widget _buildRegularText(String text) {
    final displayText = widget.message.isStreaming && _sections.length == 1
        ? text
        : text;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: MarkdownBody(
        data: displayText,
        styleSheet: _buildMarkdownStyle(widget.message.isUser),
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            launchUrl(Uri.parse(href));
          }
        },
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(bool isUser) {
    final base = isUser
        ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
        : AppTextStyles.body;

    return MarkdownStyleSheet(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.bold),
      em: base.copyWith(fontStyle: FontStyle.italic),
      h1: base.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
      h2: base.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
      h3: base.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      listBullet: base,
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: isUser ? AppColors.textOnPrimary : AppColors.primary,
        backgroundColor: isUser
            ? AppColors.textOnPrimary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.08),
      ),
      codeblockDecoration: BoxDecoration(
        color: isUser
            ? AppColors.textOnPrimary.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isUser
                ? AppColors.textOnPrimary.withValues(alpha: 0.5)
                : AppColors.primary.withValues(alpha: 0.4),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      tableBorder: TableBorder.all(
        color: isUser
            ? AppColors.textOnPrimary.withValues(alpha: 0.3)
            : AppColors.border,
      ),
      tableHead: base.copyWith(fontWeight: FontWeight.bold),
      tableBody: base,
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isUser
                ? AppColors.textOnPrimary.withValues(alpha: 0.3)
                : AppColors.border,
            width: 1,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Fallback Reflection Card (jika tidak ada structured data)
// ============================================================

class _FallbackReflectionCard extends StatelessWidget {
  final String text;
  final double? quality;
  final String missing;
  final bool isStreaming;

  const _FallbackReflectionCard({
    required this.text,
    this.quality,
    this.missing = '',
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final qualityColor = quality == null
        ? AppColors.textHint
        : quality! >= 0.8
            ? AppColors.success
            : quality! >= 0.6
                ? AppColors.accentBlue
                : quality! >= 0.4
                    ? AppColors.warning
                    : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: qualityColor.withValues(alpha: 0.05),
        border: Border.all(color: qualityColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: qualityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fact_check_outlined,
                            size: 14, color: qualityColor),
                        const SizedBox(width: 6),
                        Text(
                          'Self-Check',
                          style: AppTextStyles.caption.copyWith(
                            color: qualityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isStreaming) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: qualityColor,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (quality != null)
                          Text(
                            '${(quality! * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: qualityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Missing: $missing',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Error banner
// ============================================================

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              error,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Typing dots (tidak berubah)
// ============================================================

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
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
                    color: AppColors.primary
                        .withValues(alpha: 0.5 + bounce * 0.5),
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

// ============================================================
// Content section types & model
// ============================================================

enum ContentType {
  regular,
  plan,
  reasoning,
  action,
  reflection,
}

class _ContentSection {
  final ContentType type;
  final String text;
  final Map<String, dynamic>? metadata;
  final bool isStreaming;

  _ContentSection({
    required this.type,
    required this.text,
    this.metadata,
    this.isStreaming = false,
  });
}