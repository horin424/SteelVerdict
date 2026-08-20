import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _enabled = true;
  String? _currentBgm;

  double _bgmVolume = 0.35;
  double _sfxVolume = 0.7;

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init(bool enabled, {double? bgmVolume, double? sfxVolume}) async {
    _enabled = enabled;
    if (bgmVolume != null) _bgmVolume = bgmVolume;
    if (sfxVolume != null) _sfxVolume = sfxVolume;
    await _bgmPlayer.setVolume(enabled ? _bgmVolume : 0.0);
    await _sfxPlayer.setVolume(enabled ? _sfxVolume : 0.0);
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    await _bgmPlayer.setVolume(enabled ? _bgmVolume : 0.0);
    await _sfxPlayer.setVolume(enabled ? _sfxVolume : 0.0);
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0.0, 1.0);
    if (_enabled) {
      await _bgmPlayer.setVolume(_bgmVolume);
    }
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    if (_enabled) {
      await _sfxPlayer.setVolume(_sfxVolume);
    }
  }

  // BGM -----------------------------------------------------------------------

  Future<void> playBgm(String filename) async {
    try {
      if (_currentBgm == filename) return;
      _currentBgm = filename;
      await _bgmPlayer.stop();
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_enabled ? _bgmVolume : 0.0);
      await _bgmPlayer.play(AssetSource('audio/$filename'));
    } catch (e) {
      debugPrint('SoundService.playBgm error: $e');
    }
  }

  Future<void> stopBgm() async {
    try {
      _currentBgm = null;
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('SoundService.stopBgm error: $e');
    }
  }

  // SFX -----------------------------------------------------------------------

  Future<void> playSfx(String filename) async {
    if (!_enabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('audio/$filename'));
    } catch (e) {
      debugPrint('SoundService.playSfx error: $e');
    }
  }

  Future<void> playVictory() => playSfx('sfx_victory.wav');
  Future<void> playDefeat()  => playSfx('sfx_defeat.mp3');
  Future<void> playButton()  => playSfx('sfx_button.wav');

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
