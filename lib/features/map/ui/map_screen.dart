import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'widgets/map_settings_drawer.dart';
import 'widgets/route_planner_sheet.dart';
import '../../account/providers/settings_provider.dart';
import '../providers/map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const CameraPosition _initialPosition = CameraPosition(target: LatLng(39.920770, 32.854110), zoom: 14.0);

  BitmapDescriptor? _customRedCircleIcon;
  BitmapDescriptor? _chargingStationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _loadChargingStationMarker();
  }

  Future<void> _loadCustomMarker() async {
    const int size = 60;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.red..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _customRedCircleIcon = BitmapDescriptor.bytes(data!.buffer.asUint8List());
    });
  }

  Future<void> _loadChargingStationMarker() async {
    const int size = 50;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.green.shade600..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, borderPaint);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.4, paint);

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _chargingStationIcon = BitmapDescriptor.bytes(data!.buffer.asUint8List());
    });
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    double? minLat, maxLat, minLng, maxLng;
    for (var pos in positions) {
      if (minLat == null) {
        minLat = maxLat = pos.latitude; minLng = maxLng = pos.longitude;
      } else {
        if (pos.latitude < minLat) minLat = pos.latitude;
        if (pos.latitude > maxLat!) maxLat = pos.latitude;
        if (pos.longitude < minLng!) minLng = pos.longitude;
        if (pos.longitude > maxLng!) maxLng = pos.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(maxLat!, maxLng!), southwest: LatLng(minLat!, minLng!));
  }

  void _handleStartNavigation(MapState mapState, SettingsState settingsState, WidgetRef ref) {
    if (mapState.currentLocation == null || mapState.routePoints.isEmpty) return;

    if (settingsState.isEvModeActive && mapState.travelMode == 'driving') {
      final TextEditingController batteryController = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Akıllı Menzil Asistanı', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Yola çıkmadan önce aracınızın şu anki şarj yüzdesini (%) giriniz:'),
                const SizedBox(height: 16),
                TextField(
                  controller: batteryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Şarj (%)',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixText: '%',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  final int? batteryPercent = int.tryParse(batteryController.text);
                  if (batteryPercent != null && batteryPercent > 0 && batteryPercent <= 100) {
                    Navigator.pop(context);

                    double currentEnergy = settingsState.batteryCapacity * (batteryPercent / 100);
                    double maxRangeKm = (currentEnergy / settingsState.averageConsumption) * 100;
                    double routeDistanceKm = mapState.distanceValue / 1000;

                    if (maxRangeKm >= routeDistanceKm) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text('Menzil yeterli! Tahmini kalan menzil: ${maxRangeKm.toInt()} km')));
                      _executeCameraAnimation(mapState, ref);
                    } else {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                  SizedBox(width: 8),
                                  Text('Yetersiz Şarj'),
                                ],
                              ),
                              content: Text('Bu rota ${routeDistanceKm.toStringAsFixed(1)} km ancak mevcut şarjınızla yaklaşık ${maxRangeKm.toInt()} km gidebilirsiniz. Rotanız üzerinde şarj istasyonlarını göstermemi ister misiniz?'),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _executeCameraAnimation(mapState, ref);
                                    },
                                    child: const Text('Yine de Çık', style: TextStyle(color: Colors.grey))
                                ),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ref.read(mapProvider.notifier).findChargingStations(maxRangeKm);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Rota üzerinde, yaklaşık ${(maxRangeKm * 0.70).toInt()}. km civarında istasyonlar aranıyor...')));
                                    },
                                    child: const Text('İstasyon Bul', style: TextStyle(color: Colors.white))
                                )
                              ]
                          )
                      );
                    }
                  }
                },
                child: const Text('Hesapla', style: TextStyle(color: Colors.white)),
              )
            ],
          )
      );
    } else {
      _executeCameraAnimation(mapState, ref);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${mapState.duration} sürecek yolculuk başladı!')));
    }
  }

  Future<void> _executeCameraAnimation(MapState mapState, WidgetRef ref) async {
    final mapController = await _controller.future;
    if (!mounted || mapState.currentLocation == null) return;

    int targetIndex = mapState.routePoints.length > 5 ? 5 : (mapState.routePoints.length - 1);
    double calculatedBearing = Geolocator.bearingBetween(
      mapState.currentLocation!.latitude, mapState.currentLocation!.longitude,
      mapState.routePoints[targetIndex].latitude, mapState.routePoints[targetIndex].longitude,
    );

    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: mapState.currentLocation!, zoom: 18.5, tilt: 65.0, bearing: calculatedBearing),
    ));

    ref.read(mapProvider.notifier).startNavigation();
    ref.read(mapProvider.notifier).startLiveTracking();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final mapState = ref.watch(mapProvider);
    final bool isRouteActive = mapState.routePoints.isNotEmpty;

    ref.listen<MapState>(mapProvider, (previous, next) async {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }

      final GoogleMapController mapController = await _controller.future;

      if (next.routePoints.isNotEmpty && next.routePoints != previous?.routePoints) {
        mapController.animateCamera(CameraUpdate.newLatLngBounds(_createBounds(next.routePoints), 50));
      }

      if (next.isNavigating && next.currentLocation != null && next.currentLocation != previous?.currentLocation) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: next.currentLocation!,
              zoom: 18.5,
              tilt: 65.0,
            ),
          ),
        );
      }
    });

    Set<Polyline> polylines = {};
    if (isRouteActive) {
      polylines.add(Polyline(polylineId: const PolylineId('route_line'), points: mapState.routePoints, color: Colors.blueAccent, width: 5));
    }

    Set<Marker> markers = {};

    if (mapState.currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('current'),
        position: mapState.currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 2,
      ));
    }

    if (isRouteActive) {
      for (int i = 0; i < mapState.activeWaypoints.length; i++) {
        final waypoint = mapState.activeWaypoints[i];
        markers.add(Marker(
          markerId: MarkerId('waypoint_$i'),
          position: waypoint.location,
          icon: _customRedCircleIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: waypoint.name),
          zIndexInt: 1,
        ));
      }
    }

    if (mapState.chargingStations.isNotEmpty) {
      for (int i = 0; i < mapState.chargingStations.length; i++) {
        final station = mapState.chargingStations[i];
        markers.add(Marker(
          markerId: MarkerId('charging_station_$i'),
          position: station.location,
          icon: _chargingStationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Row(
                  children: [
                    Icon(Icons.ev_station_rounded, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Expanded(child: Text('İstasyon Ekle', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                  ],
                ),
                content: Text('"${station.name}" rotanıza ara durak olarak eklenecek ve rota baştan hesaplanacak. Onaylıyor musunuz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(mapProvider.notifier).addChargingStationToRoute(station);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('İstasyon eklendi, rota yeniden hesaplanıyor.'))
                      );
                    },
                    child: const Text('Rotaya Ekle', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
          zIndexInt: 1,
        ));
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, extendBodyBehindAppBar: true,
      drawer: MapSettingsDrawer(
        isEvModeActive: settingsState.isEvModeActive,
        onEvModeChanged: (val) => ref.read(settingsProvider.notifier).toggleEvMode(val),
      ),

      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal, initialCameraPosition: _initialPosition,
            polylines: polylines, markers: markers,
            zoomControlsEnabled: false, myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              ref.read(mapProvider.notifier).fetchCurrentLocation();
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 16, left: 16,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.background.withAlpha(240), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 28)),
            ),
          ),

          Positioned(
            bottom: (isRouteActive && !mapState.isNavigating) ? 220 : 40,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isRouteActive) ...[
                  FloatingActionButton.small(
                    heroTag: "clear_route", backgroundColor: Colors.white,
                    onPressed: () => ref.read(mapProvider.notifier).clearRoute(),
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!mapState.isNavigating) ...[
                  FloatingActionButton(
                    heroTag: "plan_route", backgroundColor: AppColors.primary,
                    onPressed: () {
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppColors.background, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (context) => const RoutePlannerSheet());
                    },
                    child: const Icon(Icons.alt_route_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                ],
                FloatingActionButton(
                  heroTag: "gps_location", backgroundColor: Colors.white,
                  onPressed: () async {
                    await ref.read(mapProvider.notifier).fetchCurrentLocation();
                    final loc = ref.read(mapProvider).currentLocation;
                    if (loc != null) {
                      final mapController = await _controller.future;
                      mapController.animateCamera(CameraUpdate.newLatLngZoom(loc, 16.5));
                    }
                  },
                  child: mapState.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ],
            ),
          ),

          if (isRouteActive && !mapState.isNavigating)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 5))]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (mapState.duration.isNotEmpty && mapState.distance.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(mapState.travelMode == 'driving' ? Icons.directions_car : Icons.directions_walk, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${mapState.duration} (${mapState.distance})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModeButton(context, ref, 'driving', Icons.directions_car_rounded, mapState.travelMode, mapState.activeWaypoints),
                        _buildModeButton(context, ref, 'walking', Icons.directions_walk_rounded, mapState.travelMode, mapState.activeWaypoints),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () => _handleStartNavigation(mapState, settingsState, ref),
                        icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                        label: const Text('Yola Çık', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, WidgetRef ref, String mode, IconData icon, String currentMode, List<RouteStop> waypoints) {
    final isActive = mode == currentMode;
    return InkWell(
      onTap: () => ref.read(mapProvider.notifier).calculateRoute(waypoints, mode: mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: isActive ? AppColors.primary.withAlpha(30) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? AppColors.primary : Colors.grey.shade300)),
        child: Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 28),
      ),
    );
  }
}