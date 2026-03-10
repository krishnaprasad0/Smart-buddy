import 'dart:convert';
import 'dart:developer';
import 'package:uuid/uuid.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/model/todo_model.dart';
import '../../domain/repository/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  final DatabaseService dbService;
  final AiService aiService;
  final _uuid = const Uuid();

  TodoRepositoryImpl({required this.dbService, required this.aiService});

  @override
  Future<List<TodoModel>> getTodos() {
    return dbService.getTodos();
  }

  @override
  Future<void> saveTodo(TodoModel todo) {
    return dbService.saveTodo(todo);
  }

  @override
  Future<void> deleteTodo(String id) {
    return dbService.deleteTodo(id);
  }

  @override
  Future<void> updateTodoStatus(String id, bool isCompleted) {
    return dbService.updateTodoStatus(id, isCompleted);
  }

  @override
  Future<TodoModel?> parseTaskWithAi(String input) async {
    try {
      final isAvailable = await aiService.isModelAvailable();
      if (!isAvailable) return null;

      final now = DateTime.now();
      final systemPrompt =
          """
Extract task details from the user's input. 
Current Time: ${now.toIso8601String()}

Return ONLY a JSON object with these keys:
- 'title': (the task description)
- 'due_date': (ISO 8601 string or null if not mentioned)
- 'priority': ('low', 'medium', or 'high')
- 'reminder_message': (a short, creative, and personalized reminder message from Smart Buddy, e.g., "Time to crush that workout! 🏋️")

Input: '$input'
Output: """;

      final aiResponse = await aiService.prompt(systemPrompt);
      log("AI Task Parse Response: $aiResponse");

      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonStr = aiResponse.substring(jsonStart, jsonEnd + 1);
        final data = jsonDecode(jsonStr);

        return TodoModel(
          id: _uuid.v4(),
          title: data['title'] ?? input,
          reminderMessage: data['reminder_message'],
          dueDate: data['due_date'] != null
              ? DateTime.parse(data['due_date'])
              : null,
          priority: TodoPriority.values.firstWhere(
            (e) => e.name == data['priority'],
            orElse: () => TodoPriority.medium,
          ),
        );
      }
    } catch (e) {
      log("Repository AI parsing failed: $e");
    }
    return null;
  }
}
