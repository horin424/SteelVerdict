import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sound_service.dart';
import '../../features/splash/splash_providers.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  final storage = ref.read(hiveStorageServiceProvider);
  final enabled = storage.getSetting('sound', defaultValue: true) as bool? ?? true;
  final bgmVol = (storage.getSetting('bgm_volume', defaultValue: 0.35) as num?)?.toDouble() ?? 0.35;
  final sfxVol = (storage.getSetting('sfx_volume', defaultValue: 0.7) as num?)?.toDouble() ?? 0.7;

  final service = SoundService();
  service.init(enabled, bgmVolume: bgmVol, sfxVolume: sfxVol);

  ref.onDispose(() => service.dispose());
  return service;
});
