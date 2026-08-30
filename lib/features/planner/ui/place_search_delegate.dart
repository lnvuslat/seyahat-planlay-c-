import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staj/features/planner/data/models/waypoint_model.dart';
import '../../../../core/theme/app_colors.dart';
const String googleMapsApiKey = 'apı_key';

class PlaceSearchDelegate extends SearchDelegate<Waypoint?> {
  @override
  String get searchFieldLabel => 'Mekan veya Şehir Ara...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestionsList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestionsList();
  }

  Widget _buildSuggestionsList() {
    if (query.isEmpty) {
      return const Center(child: Text('Rotanıza eklemek istediğiniz yeri yazın.'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _fetchPlaceSuggestions(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        } else if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Sonuç bulunamadı.'));
        }

        final results = snapshot.data!;
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
            return ListTile(
              leading: const Icon(Icons.place_outlined, color: AppColors.primary),
              title: Text(place['structured_formatting']['main_text'] ?? place['description']),
              subtitle: Text(place['structured_formatting']['secondary_text'] ?? ''),
              onTap: () async {
                final waypoint = await _fetchPlaceDetails(place['place_id'], place['description']);
                if (waypoint != null) {
                  close(context, waypoint);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum bilgisi alınamadı.')));
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _fetchPlaceSuggestions(String input) async {
    final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&language=tr&key=$googleMapsApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['predictions'];
    }
    throw Exception('API Hatası');
  }

  Future<Waypoint?> _fetchPlaceDetails(String placeId, String name) async {
    final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry,name&language=tr&key=$googleMapsApiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];

      return Waypoint(
        id: const Uuid().v4(),
        name: data['result']['name'] ?? name,
        latitude: location['lat'],
        longitude: location['lng'],
        isEvStation: false,
      );
    }
    return null;
  }
}