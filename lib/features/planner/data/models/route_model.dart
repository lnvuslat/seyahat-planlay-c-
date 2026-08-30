import 'package:hive/hive.dart';
import 'waypoint_model.dart';

part 'route_model.g.dart';

@HiveType(typeId: 2)
class RouteModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<Waypoint> waypoints;

  @HiveField(3)
  final double totalDistanceKm;

  @HiveField(4)
  final String expectedDuration;

  @HiveField(5)
  final DateTime createdAt;

  RouteModel({
    required this.id,
    required this.title,
    required this.waypoints,
    required this.totalDistanceKm,
    required this.expectedDuration,
    required this.createdAt,
  });
}