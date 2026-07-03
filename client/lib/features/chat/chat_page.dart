import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/agent_event.dart';
import '../../core/models/chat_message.dart';
import '../../core/services/agent_socket_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'providers/chat_viewmodel.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  bool _traceSheetOpen = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(chatViewModelProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _quickSend(String text) {
    _textController.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(chatPresetQueryProvider, (prev, next) {
      if (next != null && next != prev) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(chatPresetQueryProvider.notifier).state = null;
          _quickSend(next);
        });
      }
    });

    final chatState = ref.watch(chatViewModelProvider);
    final status = chatState.status;
    final connectionMode = chatState.connectionMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Row(
          children: [
            _StatusBadge(status: status, connectionMode: connectionMode),
            const SizedBox(width: 8),
            const Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => setState(() => _traceSheetOpen = !_traceSheetOpen),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(chatViewModelProvider.notifier).clearHistory();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('Hapus percakapan')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (connectionMode == ConnectionMode.rest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.md),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Mode non-realtime',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty && chatState.currentStreamingMessage == null
                ? _EmptyState(onQuickSend: _quickSend)
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: chatState.messages.length + (chatState.currentStreamingMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && chatState.currentStreamingMessage != null) {
                        return _ChatBubble(
                          message: chatState.currentStreamingMessage!,
                        );
                      }
                      final msgIndex = chatState.currentStreamingMessage != null
                          ? index - 1
                          : index;
                      final reversed = chatState.messages.length - 1 - msgIndex;
                      if (reversed < 0 || reversed >= chatState.messages.length) {
                        return const SizedBox.shrink();
                      }
                      return _ChatBubble(
                        message: chatState.messages[reversed],
                      );
                    },
                  ),
          ),
          _ChatInputBar(
            controller: _textController,
            focusNode: _inputFocus,
            isSending: chatState.isSending,
            onSend: _send,
          ),
        ],
      ),
      floatingActionButton: _traceSheetOpen
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _traceSheetOpen = true),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              child: const Icon(Icons.receipt_long_rounded),
            ),
      bottomSheet: _traceSheetOpen
          ? _AgentTraceSheet(
              traceLog: chatState.traceLog,
              connectionMode: connectionMode,
              onClose: () => setState(() => _traceSheetOpen = false),
            )
          : null,
    );
  }
}

class _StatusBadge extends ConsumerWidget {
  final AgentStatus status;
  final ConnectionMode connectionMode;

  const _StatusBadge({required this.status, required this.connectionMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connectionMode == ConnectionMode.rest) {
      return const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning);
    }
    switch (status) {
      case AgentStatus.thinking:
        return const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        );
      case AgentStatus.online:
        return const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success);
      case AgentStatus.idle:
        return const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final void Function(String text) onQuickSend;

  const _EmptyState({required this.onQuickSend});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      ('Jelaskan neural network', 'Jelaskan neural network'),
      ('Apa itu supervised learning?', 'Apa itu supervised learning?'),
      ('Bantu saya quiz', 'Bantu saya quiz'),
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            const Text('Mulai belajar dengan AI', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.sm),
            const Text('Tanya apapun seputar materi pembelajaran', style: AppTextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ActionChip(
                label: Text(s.$1, style: const TextStyle(color: AppColors.primary)),
                onPressed: () => onQuickSend(s.$2),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.textOnPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.7)),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.sm),
                  bottomRight: Radius.circular(isUser ? AppRadius.sm : AppRadius.lg),
                ),
                boxShadow: isUser ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(context),
                  if (message.prediction != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _PredictionChartCard(prediction: message.prediction!),
                  ],
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _CitationTile(citations: message.citations),
                  ],
                  if (message.webResults.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _WebSearchTile(results: message.webResults),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                color: AppColors.accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, size: 18, color: AppColors.textOnPrimary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.content.isEmpty && message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Memproses', style: AppTextStyles.body),
          const SizedBox(width: 4),
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withValues(alpha: 0.6)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          SelectableText(
            message.isStreaming ? '$content┃' : message.content,
            style: isUser
                ? AppTextStyles.body.copyWith(color: AppColors.textOnPrimary)
                : AppTextStyles.body,
          ),
        if (message.error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Chip(
            label: Text(message.error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            backgroundColor: AppColors.error.withValues(alpha: 0.1),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    );
  }

  bool get isUser => message.isUser;
  String get content => message.content;
}

class _PredictionChartCard extends StatelessWidget {
  final PredictionResult prediction;

  const _PredictionChartCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final passed = prediction.classScores.length >= 2 ? prediction.classScores[0].score : 0.0;
    final failed = prediction.classScores.length >= 2 ? prediction.classScores[1].score : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prediksi Kelulusan', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const texts = ['Lulus', 'Tidak Lulus'];
                        return Text(texts[value.toInt()], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: passed,
                      color: AppColors.success,
                      width: 24,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: failed,
                      color: AppColors.error,
                      width: 24,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationTile extends StatefulWidget {
  final List<Citation> citations;

  const _CitationTile({required this.citations});

  @override
  State<_CitationTile> createState() => _CitationTileState();
}

class _CitationTileState extends State<_CitationTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 6),
                  Text('${widget.citations.length} sumber', style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.citations.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.citations.indexOf(c) + 1}. ', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.snippet, style: AppTextStyles.caption, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (c.metadata.author != null) ...[
                              Text(c.metadata.author!, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text('${(c.score * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.success)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}

class _WebSearchTile extends StatefulWidget {
  final List<WebSearchResult> results;

  const _WebSearchTile({required this.results});

  @override
  State<_WebSearchTile> createState() => _WebSearchTileState();
}

class _WebSearchTileState extends State<_WebSearchTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.language_rounded, size: 16, color: AppColors.accentBlue),
                  const SizedBox(width: 6),
                  Text('${widget.results.length} hasil web', style: AppTextStyles.caption.copyWith(color: AppColors.accentBlue)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.results.map((r) => _WebResultItem(result: r)),
          ],
        ],
      ),
    );
  }
}

class _WebResultItem extends StatelessWidget {
  final WebSearchResult result;

  const _WebResultItem({required this.result});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri.parse(result.url);
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.source.isNotEmpty ? result.source : Uri.tryParse(result.url)?.host ?? result.url,
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
            const SizedBox(height: 2),
            Text(result.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
            const SizedBox(height: 2),
            Text(result.snippet, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (result.relevanceScore > 0) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('relevansi ${(result.relevanceScore * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentTraceSheet extends StatelessWidget {
  final List<AgentEvent> traceLog;
  final ConnectionMode connectionMode;
  final VoidCallback onClose;

  const _AgentTraceSheet({
    required this.traceLog,
    required this.connectionMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18),
                    const SizedBox(width: 8),
                    const Text('Agent Trace', style: AppTextStyles.subtitle),
                    const Spacer(),
                    Text('${traceLog.length} events', style: AppTextStyles.caption),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: traceLog.isEmpty
                    ? const Center(child: Text('Belum ada trace', style: AppTextStyles.body))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        itemCount: traceLog.length,
                        itemBuilder: (context, index) {
                          final event = traceLog[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${index + 1}.', style: AppTextStyles.caption),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.summary,
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                      if (event.detail.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(event.detail, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.textHint),
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: isSending ? null : (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Tanya AI...',
                  hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            isSending
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}
