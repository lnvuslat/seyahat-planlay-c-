import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/planner/data/models/route_model.dart';
import 'package:staj/features/planner/data/models/waypoint_model.dart';
import 'package:staj/features/planner/shared/providers/my_routes_provider.dart';
import '../../providers/map_provider.dart';
import '../../services/google_map_service.dart';


class RoutePlannerSheet extends ConsumerStatefulWidget {
  const RoutePlannerSheet({super.key});

  @override
  ConsumerState<RoutePlannerSheet> createState() => _RoutePlannerSheetState();
}

class _RoutePlannerSheetState extends ConsumerState<RoutePlannerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GoogleMapService _googleMapService = GoogleMapService();

  final List<RouteStop> _tempWaypoints = [];
  List<dynamic> _predictions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _isAddingStop = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isLoading = true);
      final results = await _googleMapService.getAutocompleteSuggestions(query);
      setState(() {
        _predictions = results;
        _isLoading = false;
      });
    });
  }

  Future<void> _addStop(String placeId, String description) async {
    setState(() {
      _isAddingStop = true;
      _predictions = [];
    });

    FocusManager.instance.primaryFocus?.unfocus();

    final LatLng? location = await _googleMapService.getPlaceCoordinates(placeId);

    if (location != null) {
      final shortName = description.split(',').first;
      setState(() {
        _tempWaypoints.add(RouteStop(
          name: shortName,
          location: location,
          placeId: placeId,
        ));
      });
      _searchController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu konumun detayları alınamadı, lütfen tekrar deneyin.')),
        );
      }
    }

    setState(() => _isAddingStop = false);
  }

  void _removeStop(int index) => setState(() => _tempWaypoints.removeAt(index));
  Future<void> _handleSaveAndDraw() async {
    final TextEditingController nameController = TextEditingController();
    final String? routeTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rotayı Kaydet', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: '...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (routeTitle == null || routeTitle.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(mapProvider.notifier).calculateRoute(_tempWaypoints);
      final mapState = ref.read(mapProvider);
      final List<Waypoint> hiveWaypoints = _tempWaypoints.map((stop) => Waypoint(
        id: stop.placeId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: stop.name,
        latitude: stop.location.latitude,
        longitude: stop.location.longitude,
      )).toList();
      final newRoute = RouteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: routeTitle,
        waypoints: hiveWaypoints,
        totalDistanceKm: mapState.distanceValue / 1000,
        expectedDuration: mapState.duration,
        createdAt: DateTime.now(),
      );

      await ref.read(myRoutesProvider.notifier).addRoute(newRoute);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$routeTitle başarıyla kaydedildi! 🗺️'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rota hesaplanırken bir hata oluştu.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding, left: 20, right: 20, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.withAlpha(100), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),

            const Text('Yolculuk Nereye?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 20),

            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Durak ekle',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _isLoading || _isAddingStop
                    ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () { _searchController.clear(); setState(() => _predictions = []); }),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            if (_predictions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _predictions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      final description = prediction['description'] ?? 'Bilinmeyen Yer';
                      final placeId = prediction['place_id'];

                      return ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.primary),
                        title: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onTap: () => _addStop(placeId, description),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (_predictions.isEmpty) ...[
              if (_tempWaypoints.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(25), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withAlpha(75))),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Expanded(child: Text('Rotanıza henüz bir durak eklemediniz. Arama yaparak eklemeye başlayın.', style: TextStyle(color: AppColors.primary))),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _tempWaypoints.length,
                    itemBuilder: (context, index) {
                      final isLast = index == _tempWaypoints.length - 1;
                      final stop = _tempWaypoints[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(isLast ? Icons.location_on : Icons.more_vert, color: isLast ? Colors.red : AppColors.primary, size: 24)],
                        ),
                        title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(isLast ? 'Son Hedef' : 'Ara Durak'),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.grey), onPressed: () => _removeStop(index)),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _tempWaypoints.isEmpty ? null : _handleSaveAndDraw,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Rotayı Kaydet ve Çiz', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ]
          ],
        ),
      ),
    );
  }
}