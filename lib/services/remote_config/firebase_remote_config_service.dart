import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../../models/game_config_model.dart';
import '../../core/constants/remote_config_keys.dart';
import 'remote_config_service.dart';

class FirebaseRemoteConfigService implements RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  GameConfigModel _cachedConfig = GameConfigModel.defaults();

  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  @override
  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        RemoteConfigKeys.rcWorldviews: '{}',
        RemoteConfigKeys.rcScenarios: '{}',
        RemoteConfigKeys.rcModeAddons: '{}',
        RemoteConfigKeys.rcTicketCosts: '{"normal":1,"tabletop":2,"epic":3,"boss":5,"practice":0,"pvp":1,"claude":3}',
        RemoteConfigKeys.rcAdUnitRewarded: 'ca-app-pub-3940256099942544/5224354917',
        RemoteConfigKeys.rcAdUnitInterstitial: 'ca-app-pub-3940256099942544/1033173712',
        RemoteConfigKeys.rcMaintenanceMode: false,
      });

      await _remoteConfig.fetchAndActivate();
      _parseAndCacheConfig();
    } catch (e) {
      debugPrint('RemoteConfig.fetchAndActivate error: $e');
      // Keep using defaults
    }
  }

  void _parseAndCacheConfig() {
    try {
      final worldviewsJson = _remoteConfig.getString(RemoteConfigKeys.rcWorldviews);
      final scenariosJson = _remoteConfig.getString(RemoteConfigKeys.rcScenarios);
      final modeAddonsJson = _remoteConfig.getString(RemoteConfigKeys.rcModeAddons);
      final ticketCostsJson = _remoteConfig.getString(RemoteConfigKeys.rcTicketCosts);
      final adRewarded = _remoteConfig.getString(RemoteConfigKeys.rcAdUnitRewarded);
      final adInterstitial = _remoteConfig.getString(RemoteConfigKeys.rcAdUnitInterstitial);

      final configMap = <String, dynamic>{
        'adUnitRewarded': adRewarded.isNotEmpty ? adRewarded : null,
        'adUnitInterstitial': adInterstitial.isNotEmpty ? adInterstitial : null,
      };

      if (worldviewsJson.isNotEmpty && worldviewsJson != '{}') {
        configMap['worldviews'] = jsonDecode(worldviewsJson);
      }
      if (scenariosJson.isNotEmpty && scenariosJson != '{}') {
        configMap['scenarios'] = jsonDecode(scenariosJson);
      }
      if (modeAddonsJson.isNotEmpty && modeAddonsJson != '{}') {
        configMap['modeAddons'] = jsonDecode(modeAddonsJson);
      }
      if (ticketCostsJson.isNotEmpty) {
        configMap['ticketCosts'] = jsonDecode(ticketCostsJson);
      }

      _cachedConfig = GameConfigModel.fromJson(configMap);
    } catch (e) {
      debugPrint('RemoteConfig parse error: $e');
      _cachedConfig = GameConfigModel.defaults();
    }
  }

  @override
  GameConfigModel getGameConfig() => _cachedConfig;

  @override
  String getAdUnitId(String slot) {
    switch (slot) {
      case 'rewarded':
        return _cachedConfig.adUnitRewarded;
      case 'interstitial':
        return _cachedConfig.adUnitInterstitial;
      default:
        return '';
    }
  }

  @override
  int getTicketCost(String gameMode) {
    return _cachedConfig.ticketCosts[gameMode] ?? 1;
  }

  @override
  bool get isMaintenanceMode {
    try {
      return _remoteConfig.getBool(RemoteConfigKeys.rcMaintenanceMode);
    } catch (e) {
      return false;
    }
  }
}
