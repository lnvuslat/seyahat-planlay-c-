import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../planner/data/models/waypoint_model.dart';

class DraftRouteNotifier extends StateNotifier<List<Waypoint>> {
  DraftRouteNotifier() : super([]);

  void addWaypoint(Waypoint point) {
    state = [...state, point];
  }

  void removeWaypoint(String id) {
    state = state.where((point) => point.id != id).toList();
  }

  void clearDraft() {
    state = [];
  }
}

final draftRouteProvider = StateNotifierProvider<DraftRouteNotifier, List<Waypoint>>((ref) {
  return DraftRouteNotifier();
});