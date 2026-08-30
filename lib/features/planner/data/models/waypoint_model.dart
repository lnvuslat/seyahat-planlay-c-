import 'package:hive/hive.dart';

part 'waypoint_model.g.dart';

@HiveType(typeId: 3)
class Waypoint {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final bool isEvStation;

  @HiveField(5)
  bool isLocked;

  Waypoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isEvStation = false,
    this.isLocked = false,
  });
}