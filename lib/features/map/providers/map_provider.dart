import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/google_map_service.dart';
import 'package:staj/features/badges/shared/providers/badges_provider.dart';

class RouteStop {
  final String name;
  final LatLng location;
  final String? placeId;
  RouteStop({required this.name, required this.location, this.placeId});
}

class MapState {
  final LatLng? currentLocation;
  final List<LatLng> routePoints;
  final List<RouteStop> activeWaypoints;
  final List<ChargingStation> chargingStations;
  final String travelMode;
  final String distance;
  final String duration;
  final int distanceValue;
  final bool isNavigating;
  final bool isLoading;
  final String? errorMessage;

  MapState({
    this.currentLocation,
    this.routePoints = const [],
    this.activeWaypoints = const [],
    this.chargingStations = const [],
    this.travelMode = 'driving',
    this.distance = '',
    this.duration = '',
    this.distanceValue = 0,
    this.isNavigating = false,
    this.isLoading = false,
    this.errorMessage,
  });

  MapState copyWith({
    LatLng? currentLocation,
    List<LatLng>? routePoints,
    List<RouteStop>? activeWaypoints,
    List<ChargingStation>? chargingStations,
    String? travelMode,
    String? distance,
    String? duration,
    int? distanceValue,
    bool? isNavigating,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      routePoints: routePoints ?? this.routePoints,
      activeWaypoints: activeWaypoints ?? this.activeWaypoints,
      chargingStations: chargingStations ?? this.chargingStations,
      travelMode: travelMode ?? this.travelMode,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      distanceValue: distanceValue ?? this.distanceValue,
      isNavigating: isNavigating ?? this.isNavigating,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
class MapNotifier extends StateNotifier<MapState> {
  final Ref ref;
  StreamSubscription<Position>? _positionStreamSubscription;
  final GoogleMapService _googleMapService = GoogleMapService();
  MapNotifier(this.ref) : super(MapState());

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Lütfen cihazınızın konum (GPS) servisini açın.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Konum izni reddedildi.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Konum izinleri kalıcı olarak kapalı. Ayarlardan açmalısınız.');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      state = state.copyWith(
        currentLocation: LatLng(position.latitude, position.longitude),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void startLiveTracking() {
    if (_positionStreamSubscription != null) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      final currentLatLng = LatLng(position.latitude, position.longitude);
      state = state.copyWith(currentLocation: currentLatLng);
      ref.read(badgesProvider.notifier).checkLocationForBadges(position.latitude, position.longitude);
    });
  }

  void stopLiveTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }

  Future<void> calculateRoute(List<RouteStop> waypoints, {String mode = 'driving'}) async {
    if (waypoints.isEmpty || state.currentLocation == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null, travelMode: mode);

    try {
      final origin = state.currentLocation!;
      final destination = waypoints.last.location;

      List<LatLng> intermediates = [];
      if (waypoints.length > 1) {
        intermediates = waypoints.sublist(0, waypoints.length - 1).map((w) => w.location).toList();
      }

      final routeInfo = await _googleMapService.getRouteCoordinates(origin, destination, intermediates, mode: mode);

      if (routeInfo != null && routeInfo.points.isNotEmpty) {
        state = state.copyWith(
            routePoints: routeInfo.points,
            activeWaypoints: waypoints,
            distance: routeInfo.distanceText,
            duration: routeInfo.durationText,
            distanceValue: routeInfo.distanceValue,
            isLoading: false
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Rota çizilemedi. (Bağlantıyı kontrol edin)');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Hata oluştu: $e');
    }
  }

  Future<void> findChargingStations(double maxRangeKm) async {
    if (state.routePoints.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      double targetDistanceKm = maxRangeKm * 0.70;
      double targetDistanceMeters = targetDistanceKm * 1000;

      LatLng targetLatLng = state.routePoints.first;
      double accumulatedDistance = 0.0;

      for (int i = 0; i < state.routePoints.length - 1; i++) {
        final point1 = state.routePoints[i];
        final point2 = state.routePoints[i + 1];

        double distanceBetween = Geolocator.distanceBetween(
          point1.latitude, point1.longitude,
          point2.latitude, point2.longitude,
        );

        accumulatedDistance += distanceBetween;

        if (accumulatedDistance >= targetDistanceMeters) {
          targetLatLng = point2;
          break;
        }
      }

      final stations = await _googleMapService.getNearbyChargingStations(targetLatLng, radius: 20000);

      if (stations.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'Rotada (${targetDistanceKm.toInt()}. kilometrede) şarj istasyonu bulunamadı.');
      } else {
        state = state.copyWith(chargingStations: stations, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'İstasyonlar aranırken hata oluştu: $e');
    }
  }

  Future<void> addChargingStationToRoute(ChargingStation station) async {
    if (state.activeWaypoints.isEmpty) return;

    final newStop = RouteStop(
      name: station.name,
      location: station.location,
      placeId: station.placeId,
    );

    List<RouteStop> updatedWaypoints = List.from(state.activeWaypoints);
    updatedWaypoints.insert(updatedWaypoints.length - 1, newStop);

    state = state.copyWith(chargingStations: []);
    await calculateRoute(updatedWaypoints, mode: state.travelMode);
  }

  void startNavigation() {
    state = state.copyWith(isNavigating: true);
  }

  void clearRoute() {
    state = state.copyWith(
        routePoints: [],
        activeWaypoints: [],
        chargingStations: [],
        distance: '',
        duration: '',
        distanceValue: 0,
        isNavigating: false
    );
  }
}
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});