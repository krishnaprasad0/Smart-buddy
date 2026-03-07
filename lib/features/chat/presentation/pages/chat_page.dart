import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Knowledge Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => context.read<ChatCubit>().clearChat(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      drawer: const _ChatDrawer(),
      body: BlocListener<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatMessageReceived) {
            // Wait for the frame to render before scrolling
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _scrollToBottom(),
            );
          }
          if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final messages = state is ChatMessageReceived
                ? state.messages
                : <ChatMessage>[];
            final isTyping = state is ChatMessageReceived
                ? state.isTyping
                : false;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return FadeIn(
                          child: const _ChatBubble(
                            message: "Typing...",
                            isAi: true,
                            isTyping: true,
                          ),
                        );
                      }
                      final msg = messages[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: _ChatBubble(
                          message: msg.text,
                          isAi: msg.isAi,
                          timeTaken: msg.timeTaken,
                          tokenCount: msg.tokenCount,
                        ),
                      );
                    },
                  ),
                ),
                _ChatInput(
                  onSend: () {
                    // Hide keyboard
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatDrawer extends StatelessWidget {
  const _ChatDrawer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final indexedDocs = context
            .read<ChatCubit>()
            .ragRepository
            .getIndexedDocuments();

        return Drawer(
          backgroundColor: AppTheme.surfaceColor,
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Text(
                    'Knowledge Assets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: indexedDocs.isEmpty
                    ? const Center(
                        child: Text(
                          'No documents uploaded',
                          style: TextStyle(color: Colors.white30),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: indexedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = indexedDocs[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.description,
                              color: AppTheme.neonCyan,
                            ),
                            title: Text(
                              doc.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${doc.chunks.length} chunks indexed',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => context.read<ChatCubit>().uploadDocument(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isAi;
  final bool isTyping;
  final Duration? timeTaken;
  final int? tokenCount;

  const _ChatBubble({
    required this.message,
    required this.isAi,
    this.isTyping = false,
    this.timeTaken,
    this.tokenCount,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAi
              ? AppTheme.surfaceColor
              : AppTheme.neonPurple.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft: isAi ? Radius.zero : null,
            bottomRight: !isAi ? Radius.zero : null,
          ),
          border: Border.all(
            color: isAi
                ? AppTheme.neonCyan.withOpacity(0.2)
                : AppTheme.neonPurple.withOpacity(0.5),
          ),
          boxShadow: [
            if (!isAi)
              BoxShadow(
                color: AppTheme.neonPurple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isTyping
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonCyan,
                    ),
                  )
                : isAi
                ? MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: Colors.white, fontSize: 15),
                      strong: const TextStyle(
                        color: AppTheme.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
            if (isAi && !isTyping && (timeTaken != null || tokenCount != null))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timeTaken != null)
                      _MetricTag(
                        icon: Icons.timer_outlined,
                        label:
                            '${(timeTaken!.inMilliseconds / 1000).toStringAsFixed(1)}s',
                      ),
                    if (timeTaken != null && tokenCount != null)
                      const SizedBox(width: 8),
                    if (tokenCount != null)
                      _MetricTag(
                        icon: Icons.token_outlined,
                        label: '$tokenCount tokens',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppTheme.neonCyan.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final VoidCallback? onSend;

  _ChatInput({this.onSend});

  void _handleSend(BuildContext context) {
    if (_controller.text.isNotEmpty) {
      context.read<ChatCubit>().sendMessage(_controller.text);
      _controller.clear();
      onSend?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.9),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _handleSend(context),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your question...',
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.neonPurple, AppTheme.neonBlue],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: () => _handleSend(context),
            ),
          ),
        ],
      ),
    );
  }
}
