import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsState {
  final bool isEvModeActive;
  final int batteryCapacity;
  final int averageConsumption;

  const SettingsState({
    this.isEvModeActive = false,
    this.batteryCapacity = 65,
    this.averageConsumption = 18,
  });

  SettingsState copyWith({
    bool? isEvModeActive,
    int? batteryCapacity,
    int? averageConsumption,
  }) {
    return SettingsState(
      isEvModeActive: isEvModeActive ?? this.isEvModeActive,
      batteryCapacity: batteryCapacity ?? this.batteryCapacity,
      averageConsumption: averageConsumption ?? this.averageConsumption,
    );
  }
}
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Box _settingsBox;

  SettingsNotifier(this._settingsBox) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final evMode = _settingsBox.get('isEvModeActive') as bool? ?? false;
    final battery = _settingsBox.get('batteryCapacity') as int? ?? 65;
    final consumption = _settingsBox.get('averageConsumption') as int? ?? 18;

    state = state.copyWith(
      isEvModeActive: evMode,
      batteryCapacity: battery,
      averageConsumption: consumption,
    );
  }

  Future<void> toggleEvMode(bool newValue) async {
    await _settingsBox.put('isEvModeActive', newValue);
    state = state.copyWith(isEvModeActive: newValue);
  }

  Future<void> updateBatteryCapacity(int newCapacity) async {
    await _settingsBox.put('batteryCapacity', newCapacity);
    state = state.copyWith(batteryCapacity: newCapacity);
  }

  // YENİ EKLENDİ: Tüketim değerini güncelleyen fonksiyon
  Future<void> updateAverageConsumption(int newConsumption) async {
    await _settingsBox.put('averageConsumption', newConsumption);
    state = state.copyWith(averageConsumption: newConsumption);
  }
}

// 3. Ana Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final box = Hive.box('settingsBox');
  return SettingsNotifier(box);
});