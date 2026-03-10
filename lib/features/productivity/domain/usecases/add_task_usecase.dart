import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../model/todo_model.dart';
import '../repository/todo_repository.dart';

class AddTaskUseCase {
  final TodoRepository repository;
  final NotificationService notificationService;
  final _uuid = const Uuid();

  AddTaskUseCase(this.repository, this.notificationService);

  Future<void> call(String rawInput) async {
    final parsedTodo = await repository.parseTaskWithAi(rawInput);

    if (parsedTodo != null) {
      await repository.saveTodo(parsedTodo);
      if (parsedTodo.dueDate != null) {
        await notificationService.scheduleNotification(
          id: parsedTodo.id.hashCode,
          title: "Smart Buddy Reminder",
          body:
              parsedTodo.reminderMessage ??
              "It's time for: ${parsedTodo.title}",
          scheduledDate: parsedTodo.dueDate!,
        );
      }
    } else {
      // Fallback to manual title if AI fails or is not available
      await repository.saveTodo(TodoModel(id: _uuid.v4(), title: rawInput));
    }
  }
}
