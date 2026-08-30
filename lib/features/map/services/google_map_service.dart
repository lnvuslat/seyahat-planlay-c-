import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ChargingStation {
  final String name;
  final LatLng location;
  final String placeId;

  ChargingStation({
    required this.name,
    required this.location,
    required this.placeId,
  });
}

class RouteInfo {
  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  final int distanceValue;

  RouteInfo({
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.distanceValue,
  });
}

class GoogleMapService {
  static const String _apiKey = 'api_key';
  Future<List<dynamic>> getAutocompleteSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_apiKey&language=tr');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return data['predictions'] ?? [];
        } else {
          print('🟡 GOOGLE PLACES UYARISI: ${data['status']} - ${data['error_message']}');
          return [];
        }
      }
    } catch (e) {
      print('🔴 Google Autocomplete Bağlantı Hatası: $e');
    }
    return [];
  }
  Future<LatLng?> getPlaceCoordinates(String placeId) async {
    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      print('🔴 Google Place Details Hatası: $e');
    }
    return null;
  }
  Future<RouteInfo?> getRouteCoordinates(LatLng origin, LatLng destination, List<LatLng> intermediates, {String mode = 'driving'}) async {
    List<LatLng> polylineCoordinates = [];

    String waypointsQuery = intermediates.map((w) => '${w.latitude},${w.longitude}').join('|');

    final urlStr = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}${waypointsQuery.isNotEmpty ? '&waypoints=$waypointsQuery' : ''}&mode=$mode&key=$_apiKey';
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          for (var leg in data['routes'][0]['legs']) {
            for (var step in leg['steps']) {
              final String stepPolyline = step['polyline']['points'];
              List<PointLatLng> decodedStepPoints = PolylinePoints.decodePolyline(stepPolyline);

              for (var point in decodedStepPoints) {
                polylineCoordinates.add(LatLng(point.latitude, point.longitude));
              }
            }
          }

          int totalDistance = 0;
          int totalDuration = 0;

          for (var leg in data['routes'][0]['legs']) {
            totalDistance += (leg['distance']['value'] as num).toInt();
            totalDuration += (leg['duration']['value'] as num).toInt();
          }

          String distStr = '${(totalDistance / 1000).toStringAsFixed(1)} km';
          String durStr = totalDuration > 3600
              ? '${totalDuration ~/ 3600} sa ${(totalDuration % 3600) ~/ 60} dk'
              : '${totalDuration ~/ 60} dk';

          return RouteInfo(
              points: polylineCoordinates,
              distanceText: distStr,
              durationText: durStr,
              distanceValue: totalDistance
          );

        } else {
          print('🟡 Google Directions API Uyarı: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('🔴 Google Rota Çizim Hatası: $e');
    }

    return null;
  }
  Future<List<ChargingStation>> getNearbyChargingStations(LatLng center, {int radius = 50000}) async {
    List<ChargingStation> stations = [];
    final urlStr = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${center.latitude},${center.longitude}&radius=$radius&type=charging_station&language=tr&key=$_apiKey';
    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;

          for (var result in results) {
            final location = result['geometry']['location'];
            stations.add(
                ChargingStation(
                  name: result['name'] ?? 'Bilinmeyen Şarj İstasyonu',
                  location: LatLng(location['lat'], location['lng']),
                  placeId: result['place_id'],
                )
            );
          }
        } else {
          print('🟡 Google Nearby Search Uyarı: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('🔴 Google Şarj İstasyonu Arama Hatası: $e');
    }

    return stations;
  }
}