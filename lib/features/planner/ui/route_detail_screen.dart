import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:staj/features/planner/data/models/route_model.dart';
import 'package:staj/features/planner/data/models/waypoint_model.dart';
import 'package:staj/features/planner/shared/providers/my_routes_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:staj/features/planner/ui/place_search_delegate.dart';

class RouteDetailScreen extends ConsumerStatefulWidget {
  final RouteModel route;

  const RouteDetailScreen({
    super.key,
    required this.route,
  });

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  late List<Waypoint> _stops;

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.route.waypoints);
  }

  void _syncWithDatabase() {
    final updatedRoute = RouteModel(
      id: widget.route.id,
      title: widget.route.title,
      waypoints: _stops,
      totalDistanceKm: widget.route.totalDistanceKm,
      expectedDuration: widget.route.expectedDuration,
      createdAt: widget.route.createdAt,
    );
    ref.read(myRoutesProvider.notifier).addRoute(updatedRoute);
  }

  void _optimizeRoute() {
    if (_stops.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Optimizasyon için en az 3 durak olmalıdır.')),
      );
      return;
    }

    setState(() {
      List<Waypoint?> optimizedList = List.filled(_stops.length, null);
      List<Waypoint> unvisited = [];

      for (int i = 0; i < _stops.length; i++) {
        if (_stops[i].isLocked) {
          optimizedList[i] = _stops[i];
        } else {
          unvisited.add(_stops[i]);
        }
      }

      Waypoint? currentPoint;

      for (int i = 0; i < optimizedList.length; i++) {
        if (optimizedList[i] != null) {
          currentPoint = optimizedList[i];
        } else {
          if (unvisited.isNotEmpty) {
            if (currentPoint == null) {
              currentPoint = unvisited.removeAt(0);
              optimizedList[i] = currentPoint;
            } else {
              Waypoint? nearest;
              double minDistance = double.infinity;

              for (var candidate in unvisited) {
                double distance = Geolocator.distanceBetween(
                  currentPoint.latitude, currentPoint.longitude,
                  candidate.latitude, candidate.longitude,
                );

                if (distance < minDistance) {
                  minDistance = distance;
                  nearest = candidate;
                }
              }

              if (nearest != null) {
                optimizedList[i] = nearest;
                unvisited.remove(nearest);
                currentPoint = nearest;
              }
            }
          }
        }
      }

      _stops = optimizedList.whereType<Waypoint>().toList();
    });

    _syncWithDatabase();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🪄 Kilitli duraklar korunarak en kısa rota hesaplandı!'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  Future<void> _addNewStop() async {
    final Waypoint? newStop = await showSearch<Waypoint?>(
      context: context,
      delegate: PlaceSearchDelegate(),
    );

    if (newStop == null) return;

    if (!mounted) return;

    setState(() {
      _stops.add(newStop);
    });

    _syncWithDatabase();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('${newStop.name} rotaya eklendi! 📍'),
          backgroundColor: AppColors.primary
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.route.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
            Text('${_stops.length} Durak Planlandı', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStop,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_location_alt_outlined, color: Colors.white),
        label: const Text('Yeni Durak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _optimizeRoute,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Akıllı Sırala (Optimize Et)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Duraklar (Sıralamak için basılı tutun)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),

          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _stops.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final stop = _stops.removeAt(oldIndex);
                  _stops.insert(newIndex, stop);
                });
                _syncWithDatabase();
              },
              itemBuilder: (context, index) {
                final Waypoint stop = _stops[index];
                final bool isLast = index == _stops.length - 1;

                final Color stopColor = stop.isEvStation ? Colors.green : AppColors.primary;
                final IconData stopIcon = stop.isEvStation ? Icons.ev_station_outlined : Icons.location_on_outlined;

                return Dismissible(
                  key: ValueKey(stop.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      _stops.removeAt(index);
                    });
                    _syncWithDatabase();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${stop.name} rotadan çıkarıldı.'), backgroundColor: AppColors.textSecondary),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.transparent,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Container(width: 2, height: 20, color: index == 0 ? Colors.transparent : AppColors.secondary.withValues(alpha: 0.3)),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: stopColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: stopColor.withValues(alpha: 0.5), width: 2)
                                ),
                                child: Icon(stopIcon, color: stopColor, size: 18),
                              ),
                              Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : AppColors.secondary.withValues(alpha: 0.3))),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: stop.isLocked ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: stop.isLocked ? AppColors.primary.withValues(alpha: 0.3) : AppColors.secondary.withValues(alpha: 0.1),
                                  width: stop.isLocked ? 1.5 : 1.0,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            stop.name,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: stop.isLocked ? AppColors.primary : AppColors.textPrimary
                                            )
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            isLast ? 'Son Hedef' : (index == 0 ? 'Başlangıç' : 'Ara Durak'),
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    icon: Icon(
                                      stop.isLocked ? Icons.lock : Icons.lock_open,
                                      color: stop.isLocked ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        stop.isLocked = !stop.isLocked;
                                      });
                                      _syncWithDatabase();
                                    },
                                  ),

                                  Icon(Icons.drag_indicator, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}