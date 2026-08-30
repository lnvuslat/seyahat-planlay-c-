import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class BatteryCapacityDialog extends ConsumerStatefulWidget {
  const BatteryCapacityDialog({super.key});

  @override
  ConsumerState<BatteryCapacityDialog> createState() => _BatteryCapacityDialogState();
}

class _BatteryCapacityDialogState extends ConsumerState<BatteryCapacityDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentCapacity = ref.read(settingsProvider).batteryCapacity;
    _controller = TextEditingController(text: currentCapacity.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Batarya Kapasitesi',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Kapasite (kWh)',
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          suffixText: 'kWh',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final newValue = int.tryParse(_controller.text.trim());
            if (newValue != null && newValue > 0) {
              ref.read(settingsProvider.notifier).updateBatteryCapacity(newValue);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}