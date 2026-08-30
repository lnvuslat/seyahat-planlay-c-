import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/features/todo/add_todo_dialog.dart';
import 'todo_provider.dart';
import 'package:staj/core/theme/app_colors.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoState = ref.watch(todoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: todoState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(child: Text('Bir hata oluştu: $err', style: const TextStyle(color: AppColors.textPrimary))),
          data: (todos) {

            if (todos.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz görev yok.\nYeni bir macera planla!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                ),
              );
            }

            final completedCount = todos.where((t) => t.isCompleted).length;
            final progress = completedCount / todos.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'İlerleme: %${(progress * 100).toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 23,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];

                      return Dismissible(
                        key: ValueKey(todo.id),
                        background: Container(
                          color: Colors.red.shade400,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          ref.read(todoProvider.notifier).deleteTodo(todo.id);
                        },
                        child: CheckboxListTile(
                          activeColor: AppColors.primary,
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                              color: todo.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: todo.note != null && todo.note!.isNotEmpty
                              ? Text(todo.note!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
                              : null,
                          value: todo.isCompleted,
                          onChanged: (_) {
                            ref.read(todoProvider.notifier).toggleCompletion(todo);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // görev ekleme bbutonu
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTodoDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}