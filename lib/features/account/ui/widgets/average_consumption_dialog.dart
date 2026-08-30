import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staj/core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class AverageConsumptionDialog extends ConsumerStatefulWidget {
  const AverageConsumptionDialog({super.key});

  @override
  ConsumerState<AverageConsumptionDialog> createState() => _AverageConsumptionDialogState();
}

class _AverageConsumptionDialogState extends ConsumerState<AverageConsumptionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final currentConsumption = ref.read(settingsProvider).averageConsumption;
    _controller = TextEditingController(text: currentConsumption.toString());
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
        'Ortalama Tüketim',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Tüketim (kWh/100km)',
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
              ref.read(settingsProvider.notifier).updateAverageConsumption(newValue);
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