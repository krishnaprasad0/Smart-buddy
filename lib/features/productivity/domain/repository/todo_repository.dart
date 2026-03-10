import '../model/todo_model.dart';

abstract class TodoRepository {
  Future<List<TodoModel>> getTodos();
  Future<void> saveTodo(TodoModel todo);
  Future<void> deleteTodo(String id);
  Future<void> updateTodoStatus(String id, bool isCompleted);
  Future<TodoModel?> parseTaskWithAi(String input);
}
