import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import 'package:staj/features/account/providers/settings_provider.dart';
import 'package:staj/features/account/ui/widgets/average_consumption_dialog.dart';
import 'package:staj/features/account/ui/widgets/battery_capacity_dialog.dart';
import '../widgets/profile_header_widget.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const ProfileHeaderWidget(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seyahat Özeti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard('Keşfedilen', '12', Icons.map_rounded),
                      _buildStatCard('Anılar', '42', Icons.photo_library_rounded),
                      _buildStatCard('Rotalar', '8', Icons.route_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Araç ve Navigasyon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.electric_car_rounded,
                    title: 'EV (Akıllı Şarj) Modu',
                    subtitle: 'Şarj duraklarını hesaba katarak rota planla',
                    trailing: Switch(
                      value: settingsState.isEvModeActive,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).toggleEvMode(val);
                      },
                      activeTrackColor: AppColors.primary,
                    ),
                  ),
                  if (settingsState.isEvModeActive) ...[
                    _buildSettingsTile(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Batarya Kapasitesi',
                      subtitle: '${settingsState.batteryCapacity} kWh (Güncelle)',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const BatteryCapacityDialog(),
                        );
                      },
                    ),

                    _buildSettingsTile(
                      icon: Icons.speed_rounded,
                      title: 'Ortalama Tüketim',
                      subtitle: '${settingsState.averageConsumption} kWh / 100km (Güncelle)',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AverageConsumptionDialog(),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }
}