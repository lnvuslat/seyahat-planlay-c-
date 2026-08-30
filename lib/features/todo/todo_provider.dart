import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'todo_model.dart';

class TodoNotifier extends StateNotifier<AsyncValue<List<TodoModel>>> {
  final Box<TodoModel> _todoBox;

  TodoNotifier(this._todoBox) : super(const AsyncValue.loading()) {
    _loadTodos();
  }
  Future<void> _loadTodos() async {
    try {
      state = const AsyncValue.loading();
      final todos = _todoBox.values.toList();
      todos.sort((a, b) {
        if (a.isCompleted == b.isCompleted) return 0;
        return a.isCompleted ? 1 : -1;
      });
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<void> addTodo(String title, {String? note}) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTodo = TodoModel(
      id: newId,
      title: title,
      note: note,
    );
    await _todoBox.put(newId, newTodo);
    await _loadTodos();
  }
  Future<void> toggleCompletion(TodoModel todo) async {
    todo.isCompleted = !todo.isCompleted;
    await todo.save();
    await _loadTodos();
  }
  Future<void> deleteTodo(String id) async {
    await _todoBox.delete(id);
    await _loadTodos();
  }
}
final todoProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<TodoModel>>>((ref) {
  final box = Hive.box<TodoModel>('todoBox');
  return TodoNotifier(box);
});