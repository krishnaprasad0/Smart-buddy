import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/chat/presentation/pages/chat_page.dart';
import 'features/model_management/presentation/pages/model_page.dart';
import 'features/chat/presentation/cubit/chat_cubit.dart';
import 'features/model_management/presentation/cubit/model_cubit.dart';
import 'core/services/ai_service.dart';
import 'core/services/local_storage_service.dart';
import 'features/chat/data/repository/rag_repository_impl.dart';
import 'features/chat/data/source/local_document_source.dart';

void main() {
  runApp(const SmartBuddyApp());
}

class SmartBuddyApp extends StatelessWidget {
  const SmartBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Repositories and Sources
    final aiService = AndroidAiService();
    final storageService = LocalStorageService();
    final ragRepository = RagRepositoryImpl();
    final documentSource = LocalDocumentSource();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ModelCubit(aiService: aiService, storageService: storageService)
                ..checkModelStatus(),
        ),
        BlocProvider(
          create: (context) => ChatCubit(
            aiService: aiService,
            ragRepository: ragRepository,
            documentSource: documentSource,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Buddy - Offline AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buddyTheme,
        home: const AppNavigationWrapper(),
      ),
    );
  }
}

class AppNavigationWrapper extends StatefulWidget {
  const AppNavigationWrapper({super.key});

  @override
  State<AppNavigationWrapper> createState() => _AppNavigationWrapperState();
}

class _AppNavigationWrapperState extends State<AppNavigationWrapper> {
  int _currentIndex = 0;
  final List<Widget> _pages = [const ChatPage(), const ModelPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.buddyTeal,
          unselectedItemColor: Colors.white30,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.memory_outlined),
              activeIcon: Icon(Icons.memory),
              label: 'Model',
            ),
          ],
        ),
      ),
    );
  }
}
