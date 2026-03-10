import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../../domain/model/chat_session.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'drawer_header_widget.dart';
import 'drawer_session_item.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        return Drawer(
          backgroundColor: AppTheme.surfaceColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Standalone Header Widget
              const DrawerHeaderWidget(),

              // New Chat Action Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.buddyTeal, AppTheme.buddyGreenLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.buddyTeal.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        context.read<ChatCubit>().createNewChat();
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'New Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'RECENT CHATS',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // Chat History List using Standalone Item Widget
              Expanded(
                child: state is ChatMessageReceived
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.allSessions.length,
                        itemBuilder: (context, index) {
                          final session = state.allSessions[index];
                          final isSelected =
                              session.id == state.currentSessionId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: DrawerSessionItem(
                              session: session,
                              isSelected: isSelected,
                              onTap: () {
                                context.read<ChatCubit>().loadChatSession(
                                  session.id,
                                );
                                Navigator.pop(context);
                              },
                              onDelete: () =>
                                  _showDeleteDialog(context, session),
                            ),
                          );
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),

              const Divider(color: Colors.white10, height: 1),

              // Dynamic Version Footer
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData
                        ? 'V${snapshot.data!.version}'
                        : 'V1.0.0';
                    return Center(
                      child: Text(
                        'Smart Buddy $version',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.1),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
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
