import 'package:hive/hive.dart';
part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? note;

  @HiveField(3)
  bool isCompleted;

  TodoModel({
    required this.id,
    required this.title,
    this.note,
    this.isCompleted = false,
  });
}