import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../splash/splash_providers.dart';
import '../../services/sound/sound_service_provider.dart';

// Locale provider
final localeProvider = StateProvider<Locale>((ref) {
  // Try to load saved locale from settings
  try {
    final storageService = ref.read(hiveStorageServiceProvider);
    final savedLocale = storageService.getSetting('locale', defaultValue: 'en') as String?;
    return Locale(savedLocale ?? 'en');
  } catch (e) {
    return const Locale('en');
  }
});

// Settings controller state
class SettingsControllerState {
  final bool isClearingData;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final double bgmVolume;
  final double sfxVolume;
  final String? message;

  const SettingsControllerState({
    this.isClearingData = false,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.bgmVolume = 0.35,
    this.sfxVolume = 0.7,
    this.message,
  });

  SettingsControllerState copyWith({
    bool? isClearingData,
    bool? notificationsEnabled,
    bool? soundEnabled,
    double? bgmVolume,
    double? sfxVolume,
    String? message,
  }) {
    return SettingsControllerState(
      isClearingData: isClearingData ?? this.isClearingData,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      message: message,
    );
  }
}

class SettingsController extends StateNotifier<SettingsControllerState> {
  final Ref _ref;

  SettingsController(this._ref) : super(const SettingsControllerState()) {
    // Load persisted sound setting + volume levels
    try {
      final storage = _ref.read(hiveStorageServiceProvider);
      final saved = storage.getSetting('sound', defaultValue: true) as bool? ?? true;
      final bgm = (storage.getSetting('bgm_volume', defaultValue: 0.35) as num?)?.toDouble() ?? 0.35;
      final sfx = (storage.getSetting('sfx_volume', defaultValue: 0.7) as num?)?.toDouble() ?? 0.7;
      state = state.copyWith(soundEnabled: saved, bgmVolume: bgm, sfxVolume: sfx);
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    _ref.read(localeProvider.notifier).state = Locale(languageCode);
    try {
      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.saveSetting('locale', languageCode);
    } catch (e) {
      debugPrint('Failed to save locale: $e');
    }
  }

  void setNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    try {
      final storage = _ref.read(hiveStorageServiceProvider);
      await storage.saveSetting('sound', value);
      await _ref.read(soundServiceProvider).setEnabled(value);
    } catch (e) {
      debugPrint('setSound error: $e');
    }
  }

  Future<void> setBgmVolume(double value) async {
    state = state.copyWith(bgmVolume: value);
    try {
      final storage = _ref.read(hiveStorageServiceProvider);
      await storage.saveSetting('bgm_volume', value);
      await _ref.read(soundServiceProvider).setBgmVolume(value);
    } catch (e) {
      debugPrint('setBgmVolume error: $e');
    }
  }

  Future<void> setSfxVolume(double value) async {
    state = state.copyWith(sfxVolume: value);
    try {
      final storage = _ref.read(hiveStorageServiceProvider);
      await storage.saveSetting('sfx_volume', value);
      await _ref.read(soundServiceProvider).setSfxVolume(value);
    } catch (e) {
      debugPrint('setSfxVolume error: $e');
    }
  }

  Future<bool> clearAllData() async {
    state = state.copyWith(isClearingData: true);
    try {
      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.clearAll();
      state = state.copyWith(isClearingData: false, message: 'All data cleared.');
      return true;
    } catch (e) {
      state = state.copyWith(isClearingData: false, message: 'Failed to clear data: $e');
      return false;
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsControllerState>((ref) {
  return SettingsController(ref);
});
