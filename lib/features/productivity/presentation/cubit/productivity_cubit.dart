import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'productivity_state.dart';
import '../../domain/model/todo_model.dart';
import '../../domain/usecases/add_task_usecase.dart';
import '../../domain/usecases/delete_todo_usecase.dart';
import '../../domain/usecases/get_todos_usecase.dart';
import '../../domain/usecases/toggle_todo_usecase.dart';

class ProductivityCubit extends Cubit<ProductivityState> {
  final GetTodosUseCase getTodosUseCase;
  final AddTaskUseCase addTaskUseCase;
  final ToggleTodoUseCase toggleTodoUseCase;
  final DeleteTodoUseCase deleteTodoUseCase;

  ProductivityCubit({
    required this.getTodosUseCase,
    required this.addTaskUseCase,
    required this.toggleTodoUseCase,
    required this.deleteTodoUseCase,
  }) : super(ProductivityInitial()) {
    loadTodos();
  }

  Future<void> loadTodos() async {
    emit(ProductivityLoading());
    try {
      final todos = await getTodosUseCase();
      emit(TodoListReady(todos: todos));
    } catch (e) {
      emit(ProductivityError("Failed to load tasks: $e"));
    }
  }

  Future<void> addTask(String rawInput) async {
    if (state is! TodoListReady) return;
    final currentState = state as TodoListReady;

    emit(currentState.copyWith(isParsing: true));

    try {
      await addTaskUseCase(rawInput);
      await loadTodos();
    } catch (e) {
      emit(
        currentState.copyWith(
          isParsing: false,
          error: "Task addition failed: $e",
        ),
      );
      await loadTodos();
    }
  }

  Future<void> toggleTodo(TodoModel todo) async {
    try {
      await toggleTodoUseCase(todo.id, !todo.isCompleted);
      await loadTodos();
    } catch (e) {
      log("Error toggling todo: $e");
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      await deleteTodoUseCase(id);
      await loadTodos();
    } catch (e) {
      log("Error deleting todo: $e");
    }
  }
}
