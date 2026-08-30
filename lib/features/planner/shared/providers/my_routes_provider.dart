import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../data/route_storage_service.dart';
final routeStorageProvider = Provider<RouteStorageService>((ref) {
  return RouteStorageService();
});
class MyRoutesNotifier extends StateNotifier<List<RouteModel>> {
  final RouteStorageService _storageService;
  MyRoutesNotifier(this._storageService) : super([]) {
    _loadRoutes();
  }
  void _loadRoutes() {
    state = _storageService.getAllRoutes();
  }
  Future<void> addRoute(RouteModel route) async {
    await _storageService.saveRoute(route);
    _loadRoutes();
  }
  Future<void> removeRoute(String id) async {
    await _storageService.deleteRoute(id);
    _loadRoutes();
  }
}

final myRoutesProvider = StateNotifierProvider<MyRoutesNotifier, List<RouteModel>>((ref) {
  final storageService = ref.read(routeStorageProvider);
  return MyRoutesNotifier(storageService);
});