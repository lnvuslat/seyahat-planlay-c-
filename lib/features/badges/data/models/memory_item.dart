import 'package:hive/hive.dart';

part 'memory_item.g.dart';

@HiveType(typeId: 5)
class MemoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String note;

  @HiveField(4)
  final String categoryIcon;

  @HiveField(5)
  final String? imagePath;


  MemoryItem({
    required this.id,
    required this.date,
    required this.title,
    required this.note,
    required this.categoryIcon,
    this.imagePath,
  });
}