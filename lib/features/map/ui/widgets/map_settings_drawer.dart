import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MapSettingsDrawer extends StatelessWidget {
  final bool isEvModeActive;
  final ValueChanged<bool> onEvModeChanged;

  const MapSettingsDrawer({
    super.key,
    required this.isEvModeActive,
    required this.onEvModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.map_outlined, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'Özelleştir',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Şarj İstasyonları', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Haritada şarj noktalarını göster'),
            secondary: Icon(
              Icons.ev_station,
              color: isEvModeActive ? Colors.green : Colors.grey,
            ),
            activeColor: Colors.green,
            activeTrackColor: Colors.green.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            value: isEvModeActive,
            onChanged: (bool value) {
              onEvModeChanged(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'İstasyonlar haritaya yükleniyor ⚡' : 'İstasyonlar gizlendi',
                  ),
                  backgroundColor: value ? Colors.green : AppColors.secondary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}