import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../domain/model/chat_session.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return Drawer(
          backgroundColor: AppTheme.surfaceColor,
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Text(
                    'Smart Buddy',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.add_comment_rounded,
                  color: AppTheme.buddyTeal,
                ),
                title: const Text(
                  'New Chat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  context.read<ChatCubit>().createNewChat();
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Colors.white10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Previous Chats',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: state is ChatMessageReceived
                    ? ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: state.allSessions.length,
                        itemBuilder: (context, index) {
                          final session = state.allSessions[index];
                          final isSelected =
                              session.id == state.currentSessionId;

                          return ListTile(
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: isSelected
                                  ? AppTheme.buddyTeal
                                  : Colors.white24,
                              size: 20,
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Colors.white24,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(context, session),
                                  ),
                            onTap: () {
                              context.read<ChatCubit>().loadChatSession(
                                session.id,
                              );
                              Navigator.pop(context);
                            },
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const Divider(color: Colors.white10),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Smart Buddy v1.0',
                  style: TextStyle(color: Colors.white10, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, ChatSession session) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Chat?'),
        content: Text('Are you sure you want to delete "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white30),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatCubit>().deleteSession(session.id);
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
