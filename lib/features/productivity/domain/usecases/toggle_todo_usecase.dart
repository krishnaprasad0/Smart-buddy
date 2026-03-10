import '../repository/todo_repository.dart';

class ToggleTodoUseCase {
  final TodoRepository repository;

  ToggleTodoUseCase(this.repository);

  Future<void> call(String id, bool isCompleted) {
    return repository.updateTodoStatus(id, isCompleted);
  }
}
