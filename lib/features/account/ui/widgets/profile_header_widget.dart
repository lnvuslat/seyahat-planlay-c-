import 'package:flutter/material.dart';
import 'package:staj/core/theme/app_colors.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=2070',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}