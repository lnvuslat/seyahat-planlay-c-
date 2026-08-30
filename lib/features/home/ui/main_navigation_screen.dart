import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/features/account/ui/screens/account_screen.dart';
import 'package:staj/features/badges/ui/screens/badges_screen.dart';
import 'package:staj/features/map/ui/map_screen.dart';
import 'package:staj/features/planner/ui/my_routes_screen.dart';
import 'package:staj/features/todo/todo_screen.dart';

import 'package:staj/shared/providers/bottom_nav_provider.dart';
import 'package:staj/shared/widgets/custom_bottom_nav_bar.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> screens = [
      const MyRoutesScreen(),
      const BadgesScreen(),
      const MapScreen(),
      const TodoScreen(),
      const AccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}