import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/voice_service.dart';
import '../cubit/productivity_cubit.dart';
import '../cubit/productivity_state.dart';
import '../../domain/model/todo_model.dart';

class ProductivityDashboardPage extends StatefulWidget {
  const ProductivityDashboardPage({super.key});

  @override
  State<ProductivityDashboardPage> createState() =>
      _ProductivityDashboardPageState();
}

class _ProductivityDashboardPageState extends State<ProductivityDashboardPage> {
  final TextEditingController _taskController = TextEditingController();
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocConsumer<ProductivityCubit, ProductivityState>(
        listener: (context, state) {
          if (state is TodoListReady && state.error != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is ProductivityLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.buddyTeal),
            );
          }

          if (state is TodoListReady) {
            return _buildDashboard(context, state);
          }

          return const Center(child: Text("Initializing..."));
        },
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, TodoListReady state) {
    return Column(
      children: [
        _buildHeader(),
        _buildInputSection(context, state.isParsing),
        Expanded(
          child: state.todos.isEmpty
              ? _buildEmptyState()
              : _buildTodoList(context, state.todos),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                child: const Text(
                  'Daily Tasks',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Managed by Smart Buddy AI',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FadeInDown(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.buddyTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: AppTheme.buddyTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, bool isParsing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: FadeInUp(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a task (e.g., "call mom tomorrow")',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submitTask(),
                ),
              ),
              IconButton(
                onPressed: _toggleListening,
                icon: Icon(
                  _isListening
                      ? Icons.stop_circle_rounded
                      : Icons.mic_none_rounded,
                  color: _isListening ? Colors.redAccent : Colors.white30,
                ),
              ),
              if (isParsing)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.buddyGreen,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: _submitTask,
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppTheme.buddyGreen,
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList(BuildContext context, List<TodoModel> todos) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 50),
          child: _buildTodoCard(context, todo),
        );
      },
    );
  }

  Widget _buildTodoCard(BuildContext context, TodoModel todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: todo.isCompleted
            ? Colors.white.withOpacity(0.02)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => context.read<ProductivityCubit>().toggleTodo(todo),
          activeColor: AppTheme.buddyGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isCompleted ? Colors.white30 : Colors.white,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: todo.dueDate != null
            ? Text(
                _formatDate(todo.dueDate!),
                style: TextStyle(
                  color: AppTheme.buddyTeal.withOpacity(0.6),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24),
          onPressed: () =>
              context.read<ProductivityCubit>().deleteTodo(todo.id),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day));
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    return '${date.day}/${date.month}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            'Your space is clear',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask Smart Buddy to plan your day.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _submitTask() {
    final text = _taskController.text.trim();
    if (text.isNotEmpty) {
      context.read<ProductivityCubit>().addTask(text);
      _taskController.clear();
    }
  }

  void _toggleListening() async {
    final voiceService = VoiceService();
    if (_isListening) {
      await voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await voiceService.startListening((text) {
        setState(() {
          _taskController.text = text;
          _isListening = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
