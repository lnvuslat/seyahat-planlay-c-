import 'package:hive_flutter/hive_flutter.dart';
import 'models/route_model.dart';

class RouteStorageService {
  final String _boxName = 'routesBox';

  Box<RouteModel> get _box => Hive.box<RouteModel>(_boxName);

  Future<void> saveRoute(RouteModel route) async {
    await _box.put(route.id, route);
  }

  List<RouteModel> getAllRoutes() {
    return _box.values.toList();
  }

  Future<void> deleteRoute(String id) async {
    await _box.delete(id);
  }
}