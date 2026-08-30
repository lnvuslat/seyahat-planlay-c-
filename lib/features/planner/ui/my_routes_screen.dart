import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:staj/features/map/providers/map_provider.dart';
import 'package:staj/features/planner/data/models/route_model.dart';
import 'package:staj/features/planner/shared/providers/my_routes_provider.dart';
import 'package:staj/shared/providers/bottom_nav_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'route_detail_screen.dart';

class MyRoutesScreen extends ConsumerWidget {
  const MyRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedRoutes = ref.watch(myRoutesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
            'Rotalarım',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 24)
        ),
        actions: [
          IconButton(
            tooltip: 'Yeni Rota Oluştur',
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: savedRoutes.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: savedRoutes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final route = savedRoutes[savedRoutes.length - 1 - index];

          return Dismissible(
            key: ValueKey(route.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
            ),
            onDismissed: (direction) {
              ref.read(myRoutesProvider.notifier).removeRoute(route.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${route.title} silindi.'), backgroundColor: AppColors.textSecondary),
              );
            },
            child: _buildRouteBox(context, route, ref),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: AppColors.secondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Henüz kayıtlı bir rotan yok.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Harita üzerinden yeni bir rota planla\nve buraya kaydet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteBox(BuildContext context, RouteModel route, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RouteDetailScreen(route: route),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.directions_car_filled_outlined, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '${route.waypoints.length} Durak Planlandı',
                            style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Haritada Aç',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                  ),
                  icon: const Icon(Icons.map_outlined, color: AppColors.secondary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${route.title} haritaya yükleniyor... 🗺️'),
                          backgroundColor: AppColors.secondary
                      ),
                    );

                    final mapStops = route.waypoints.map((wp) => RouteStop(
                      name: wp.name,
                      location: LatLng(wp.latitude, wp.longitude),
                      placeId: wp.id,
                    )).toList();
                    ref.read(mapProvider.notifier).calculateRoute(mapStops);
                    ref.read(bottomNavIndexProvider.notifier).state = 2;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}