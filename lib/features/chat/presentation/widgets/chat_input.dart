import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import 'knowledge_base_bottom_sheet.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final VoidCallback? onSend;

  ChatInput({super.key, this.onSend});

  void _handleSend(BuildContext context) {
    if (_controller.text.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(_controller.text);
      _controller.clear();
      onSend?.call();
    }
  }

  void _showKnowledgeBase(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const KnowledgeBaseBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final isGenerating = state is ChatMessageReceived && state.isGenerating;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.9),
            border: const Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.attach_file_rounded,
                  color: Colors.white54,
                ),
                onPressed: isGenerating
                    ? null
                    : () => _showKnowledgeBase(context),
                tooltip: 'Knowledge Base',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !isGenerating,
                  onSubmitted: (_) => _handleSend(context),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: isGenerating
                        ? 'Smart Buddy is thinking...'
                        : 'Type your question...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.black26,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGenerating ? Colors.redAccent : AppTheme.buddyTeal,
                ),
                child: IconButton(
                  icon: Icon(
                    isGenerating ? Icons.stop_rounded : Icons.send_rounded,
                    color: Colors.white,
                  ),
                  onPressed: isGenerating
                      ? () => context.read<ChatCubit>().stopGeneration()
                      : () => _handleSend(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
