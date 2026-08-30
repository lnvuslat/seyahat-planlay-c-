import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/badges/shared/providers/badges_provider.dart';
import '../widgets/badge_card.dart';
import 'city_visits_screen.dart';


class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {

  @override
  Widget build(BuildContext context) {
    final badgesState = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Seyahat Pasaportum',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: badgesState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          _buildStatsCard(badgesState.cities),

          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: badgesState.cities.length,
              itemBuilder: (context, index) {
                final city = badgesState.cities[index];

                return BadgeCard(
                  cityId: city.id,
                  cityName: city.name,
                  isUnlocked: city.isUnlocked,
                  onTap: () {
                    if (city.isUnlocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CityVisitsScreen(
                            cityId: city.id,
                            cityName: city.name,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${city.name} rozeti henüz kilitli! 🗺️')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatsCard(List<dynamic> cities) {
    final unlockedCount = cities.where((c) => c.isUnlocked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(70),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keşfedilen Şehirler',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unlockedCount / 81',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 48),
          ],
        ),
      ),
    );
  }
}