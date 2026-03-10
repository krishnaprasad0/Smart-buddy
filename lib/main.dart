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
import 'core/services/database_service.dart';
import 'features/productivity/presentation/cubit/productivity_cubit.dart';
import 'features/productivity/presentation/pages/productivity_dashboard_page.dart';
import 'features/productivity/data/repository/todo_repository_impl.dart';
import 'features/productivity/domain/usecases/add_task_usecase.dart';
import 'features/productivity/domain/usecases/delete_todo_usecase.dart';
import 'features/productivity/domain/usecases/get_todos_usecase.dart';
import 'features/productivity/domain/usecases/toggle_todo_usecase.dart';
import 'core/services/notification_service.dart';
import 'core/services/voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await VoiceService().init();
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
    final databaseService = DatabaseService();

    // Productivity Repositories and UseCases
    final todoRepository = TodoRepositoryImpl(
      dbService: databaseService,
      aiService: aiService,
    );
    final getTodosUseCase = GetTodosUseCase(todoRepository);
    final addTaskUseCase = AddTaskUseCase(
      todoRepository,
      NotificationService(),
    );
    final toggleTodoUseCase = ToggleTodoUseCase(todoRepository);
    final deleteTodoUseCase = DeleteTodoUseCase(todoRepository);

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
            dbService: databaseService,
          ),
        ),
        BlocProvider(
          create: (context) => ProductivityCubit(
            getTodosUseCase: getTodosUseCase,
            addTaskUseCase: addTaskUseCase,
            toggleTodoUseCase: toggleTodoUseCase,
            deleteTodoUseCase: deleteTodoUseCase,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Buddy',
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
  final List<Widget> _pages = [
    const ChatPage(),
    const ProductivityDashboardPage(),
    const ModelPage(),
  ];

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
              icon: Icon(Icons.task_alt_outlined),
              activeIcon: Icon(Icons.task_alt),
              label: 'Tasks',
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
