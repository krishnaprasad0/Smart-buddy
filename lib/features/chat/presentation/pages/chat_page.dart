import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_drawer.dart';
import '../widgets/chat_input.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  double _lastBottomInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding
        .instance
        .platformDispatcher
        .views
        .first
        .viewInsets
        .bottom;
    if (bottomInset > _lastBottomInset) {
      // Keyboard is opening
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
    _lastBottomInset = bottomInset;
  }

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
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.chatBg,
      drawer: const ChatDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          FocusScope.of(context).unfocus();
        }
      },
      appBar: AppBar(
        title: const Text('Smart Buddy'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppTheme.buddyTeal,
            ),
            onPressed: () => context.read<ChatCubit>().clearChat(),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          if (state is ChatMessageReceived) {
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
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: messages.length + (isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const ChatBubble(
                        message: '',
                        isAi: true,
                        isTyping: true,
                      );
                    }
                    final message = messages[index];
                    return ChatBubble(
                      message: message.text,
                      isAi: message.isAi,
                      timeTaken: message.timeTaken,
                      tokenCount: message.tokenCount,
                    );
                  },
                ),
              ),
              ChatInput(
                onSend: () => WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
