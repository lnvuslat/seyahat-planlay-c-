import 'package:hive/hive.dart';
import 'memory_item.dart';

part 'city_badge.g.dart';

@HiveType(typeId: 4)
class CityBadge extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  bool isUnlocked;

  @HiveField(5)
  DateTime? unlockedAt;

  @HiveField(6)
  HiveList<MemoryItem>? memories;

  CityBadge({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isUnlocked = false,
    this.unlockedAt,
    this.memories,
  });
}