import 'package:equatable/equatable.dart';
import '../../domain/model/todo_model.dart';

abstract class ProductivityState extends Equatable {
  const ProductivityState();

  @override
  List<Object?> get props => [];
}

class ProductivityInitial extends ProductivityState {}

class ProductivityLoading extends ProductivityState {}

class TodoListReady extends ProductivityState {
  final List<TodoModel> todos;
  final bool isParsing;
  final String? error;

  const TodoListReady({
    required this.todos,
    this.isParsing = false,
    this.error,
  });

  @override
  List<Object?> get props => [todos, isParsing, error];

  TodoListReady copyWith({
    List<TodoModel>? todos,
    bool? isParsing,
    String? error,
  }) {
    return TodoListReady(
      todos: todos ?? this.todos,
      isParsing: isParsing ?? this.isParsing,
      error: error ?? this.error,
    );
  }
}

class ProductivityError extends ProductivityState {
  final String message;

  const ProductivityError(this.message);

  @override
  List<Object?> get props => [message];
}
