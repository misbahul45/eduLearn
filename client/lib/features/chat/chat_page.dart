import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatBubble(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _isLoading = true;
    });
    _controller.clear();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatBubble(
          text: 'Maaf, fitur chat masih dalam pengembangan. Silakan coba lagi nanti.',
          isUser: false,
          time: DateTime.now(),
        ));
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_messages.isEmpty)
          Expanded(
            child: _buildEmptyState(),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Mengetik...', style: TextStyle(color: AppColors.textHint)),
                      ],
                    ),
                  );
                }
                final msg = _messages[index];
                return _buildBubble(msg);
              },
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Tanya sesuatu...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.lg),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.textOnPrimary, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.md),
          const Text('Mulai Belajar', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ajukan pertanyaan tentang materi\npelajaranmu di sini',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatBubble msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.md),
            topRight: const Radius.circular(AppSpacing.md),
            bottomLeft: msg.isUser
                ? const Radius.circular(AppSpacing.md)
                : Radius.zero,
            bottomRight: msg.isUser
                ? Radius.zero
                : const Radius.circular(AppSpacing.md),
          ),
          border: msg.isUser ? null : Border.all(color: AppColors.border),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 11,
                color: msg.isUser
                    ? AppColors.textOnPrimary.withValues(alpha: 0.7)
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
