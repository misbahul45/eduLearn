import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/chat_viewmodel.dart';
import '../../core/services/agent_socket_service.dart';
import 'widgets/agent_trace_sheet.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/connection_mode_banner.dart';
import 'widgets/empty_state.dart';
import 'widgets/status_badge.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  bool _traceSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      final vm = ref.read(chatViewModelProvider.notifier);
      if (ref.read(chatViewModelProvider).connectionMode ==
          ConnectionMode.realtime) {
        vm.reconnectWs();
      }
    }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Row(
          children: [
            StatusBadge(
              status: chatState.status,
              connectionMode: chatState.connectionMode,
            ),
            const SizedBox(width: 8),
            const Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () =>
                setState(() => _traceSheetOpen = !_traceSheetOpen),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                ref.read(chatViewModelProvider.notifier).clearHistory();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Hapus percakapan'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.connectionMode == ConnectionMode.rest)
            ConnectionModeBanner(
              onRetry: () =>
                  ref.read(chatViewModelProvider.notifier).reconnectWs(),
            ),
          Expanded(
            child: chatState.messages.isEmpty &&
                    chatState.currentStreamingMessage == null
                ? EmptyState(onQuickSend: _quickSend)
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: chatState.messages.length +
                        (chatState.currentStreamingMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 &&
                          chatState.currentStreamingMessage != null) {
                        return ChatBubble(
                          message: chatState.currentStreamingMessage!,
                        );
                      }
                      final msgIndex =
                          chatState.currentStreamingMessage != null
                              ? index - 1
                              : index;
                      final reversed =
                          chatState.messages.length - 1 - msgIndex;
                      if (reversed < 0 ||
                          reversed >= chatState.messages.length) {
                        return const SizedBox.shrink();
                      }
                      return ChatBubble(
                        message: chatState.messages[reversed],
                      );
                    },
                  ),
          ),
          ChatInputBar(
            controller: _textController,
            focusNode: _inputFocus,
            isSending: chatState.isSending,
            onSend: _send,
          ),
        ],
      ),
      bottomSheet: _traceSheetOpen
          ? AgentTraceSheet(
              traceLog: chatState.traceLog,
              connectionMode: chatState.connectionMode,
              onClose: () => setState(() => _traceSheetOpen = false),
            )
          : null,
    );
  }
}
