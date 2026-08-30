import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/shared/providers/bottom_nav_provider.dart';
import '../../core/theme/app_colors.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildNavItem(ref, icon: Icons.lightbulb_outline, index: 0, currentIndex: currentIndex),
            _buildNavItem(ref, icon: Icons.shield_outlined, index: 1, currentIndex: currentIndex),
            _buildNavItem(ref, icon: Icons.map_outlined, index: 2, currentIndex: currentIndex, iconSize: 40),

            _buildNavItem(ref, icon: Icons.checklist, index: 3, currentIndex: currentIndex),
            _buildNavItem(ref, icon: Icons.person_outline, index: 4, currentIndex: currentIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      WidgetRef ref, {
        required IconData icon,
        required int index,
        required int currentIndex,
        double iconSize = 32,
      }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(bottomNavIndexProvider.notifier).state = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(

            color: isSelected ? AppColors.background.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: isSelected ? AppColors.background : AppColors.background.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}