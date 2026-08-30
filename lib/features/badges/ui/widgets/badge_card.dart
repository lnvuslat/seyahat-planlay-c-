import 'package:flutter/material.dart';
import 'package:staj/core/theme/app_colors.dart';

class BadgeCard extends StatelessWidget {
  final String cityId;
  final String cityName;
  final bool isUnlocked;
  final VoidCallback onTap;

  const BadgeCard({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Açık olanlar parlak zemin, kilitli olanlar sönük gri
          color: isUnlocked ? AppColors.surface : Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnlocked ? AppColors.primary.withAlpha(50) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
            BoxShadow(
              color: AppColors.primary.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 60,
                  color: isUnlocked ? AppColors.primary : Colors.grey.withAlpha(100),
                ),
                if (!isUnlocked)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                cityName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isUnlocked ? AppColors.textPrimary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}