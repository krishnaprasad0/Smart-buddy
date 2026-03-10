import '../model/todo_model.dart';
import '../repository/todo_repository.dart';

class GetTodosUseCase {
  final TodoRepository repository;

  GetTodosUseCase(this.repository);

  Future<List<TodoModel>> call() {
    return repository.getTodos();
  }
}
