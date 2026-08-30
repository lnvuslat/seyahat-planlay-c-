import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:staj/features/badges/data/models/city_badge.dart';
import 'package:staj/features/badges/data/models/memory_item.dart';
import 'package:staj/core/constants/turkey_cities.dart';

class BadgesState {
  final List<CityBadge> cities;
  final bool isLoading;
  final String? errorMessage;

  BadgesState({
    this.cities = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  BadgesState copyWith({
    List<CityBadge>? cities,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BadgesState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class BadgesNotifier extends StateNotifier<BadgesState> {
  final Box<CityBadge> _badgesBox = Hive.box<CityBadge>('badgesBox');
  final Box<MemoryItem> _memoryBox = Hive.box<MemoryItem>('memoryBox');

  BadgesNotifier() : super(BadgesState(isLoading: true)) {
    _initDatabase();
  }

  void _initDatabase() {
    if (_badgesBox.isEmpty) {
      _badgesBox.addAll(TurkeyCities.defaultCities);
    }
    _loadCitiesIntoState();
  }

  void _loadCitiesIntoState() {
    final cities = List<CityBadge>.from(_badgesBox.values);
    state = state.copyWith(cities: cities, isLoading: false);
  }

  Future<void> unlockCityBadge(String cityId) async {
    final city = _badgesBox.values.firstWhere((c) => c.id == cityId);

    if (!city.isUnlocked) {
      city.isUnlocked = true;
      city.unlockedAt = DateTime.now();
      await city.save();
      _loadCitiesIntoState();
    }
  }
  Future<void> checkLocationForBadges(double currentLat, double currentLng) async {
    final lockedCities = state.cities.where((c) => !c.isUnlocked).toList();

    for (var city in lockedCities) {
      final distanceInMeters = Geolocator.distanceBetween(
        currentLat, currentLng,
        city.latitude, city.longitude,
      );

      if (distanceInMeters <= 20000) {
        await unlockCityBadge(city.id);
      }
    }
  }
  Future<void> addMemoryToCity(String cityId, MemoryItem memory) async {
    try {
      await _memoryBox.put(memory.id, memory);
      final city = _badgesBox.values.firstWhere((c) => c.id == cityId);
      city.memories ??= HiveList<MemoryItem>(_memoryBox);
      city.memories!.add(memory);
      await city.save();
      _loadCitiesIntoState();
    }
    catch (e) {
      print("Anı kaydedilirken kritik bir veritabanı hatası oluştu: $e");
    }
  }
}

final badgesProvider = StateNotifierProvider<BadgesNotifier, BadgesState>((ref) {
  return BadgesNotifier();
});