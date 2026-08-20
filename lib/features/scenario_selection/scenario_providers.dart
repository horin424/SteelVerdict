import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scenario_model.dart';
import '../../services/game_config/game_config_providers.dart';
import '../splash/splash_providers.dart';
import '../home/home_providers.dart';
import '../shop/shop_providers.dart';

const _kUnlockedKey = 'unlocked_scenarios';

// All scenarios from Firestore game config, merged with locally unlocked IDs
final scenariosProvider = Provider<List<ScenarioModel>>((ref) {
  final storage = ref.watch(hiveStorageServiceProvider);
  final gameConfig = ref.watch(gameConfigProvider);

  // Load locally persisted unlocks
  final raw = storage.getSetting(_kUnlockedKey, defaultValue: '[]') as String;
  final localIds = List<String>.from(jsonDecode(raw) as List);

  return gameConfig.scenarios.values.map((s) {
    final isLocallyUnlocked = localIds.contains(s.scenarioId);
    return isLocallyUnlocked ? s.copyWith(isUnlocked: true) : s;
  }).toList()..sort((a, b) => a.difficulty.compareTo(b.difficulty));
});

// Unlocked scenarios only
final unlockedScenariosProvider = Provider<List<ScenarioModel>>((ref) {
  final scenarios = ref.watch(scenariosProvider);
  return scenarios.where((s) => s.isUnlocked || s.isFree).toList();
});

// Scenarios filtered by battle type
final scenariosByTypeProvider =
    Provider.family<List<ScenarioModel>, BattleType>((ref, type) {
      final scenarios = ref.watch(scenariosProvider);
      return scenarios.where((s) => s.battleType == type).toList();
    });

// Scenarios filtered by worldview key AND battle type
final scenariosByWorldviewAndTypeProvider =
    Provider.family<List<ScenarioModel>, (String, BattleType)>((ref, args) {
      final (worldviewKey, type) = args;
      final scenarios = ref.watch(scenariosProvider);
      return scenarios
          .where((s) => s.battleType == type && s.worldviewKey == worldviewKey)
          .toList();
    });

// Scenario unlock controller
class ScenarioUnlockState {
  final bool isUnlocking;
  final String? error;

  const ScenarioUnlockState({this.isUnlocking = false, this.error});

  ScenarioUnlockState copyWith({bool? isUnlocking, String? error}) {
    return ScenarioUnlockState(
      isUnlocking: isUnlocking ?? this.isUnlocking,
      error: error,
    );
  }
}

class ScenarioUnlockController extends StateNotifier<ScenarioUnlockState> {
  final Ref _ref;

  ScenarioUnlockController(this._ref) : super(const ScenarioUnlockState());

  Future<void> _persistUnlock(String scenarioId) async {
    final storage = _ref.read(hiveStorageServiceProvider);
    final raw = storage.getSetting(_kUnlockedKey, defaultValue: '[]') as String;
    final ids = List<String>.from(jsonDecode(raw) as List);
    if (!ids.contains(scenarioId)) {
      ids.add(scenarioId);
      await storage.saveSetting(_kUnlockedKey, jsonEncode(ids));
    }
    _ref.invalidate(scenariosProvider);
  }

  Future<bool> unlockWithAd(String scenarioId) async {
    state = state.copyWith(isUnlocking: true, error: null);
    try {
      final adService = _ref.read(adServiceProvider);
      await adService.loadRewardedAd();
      final rewarded = await adService.showRewardedAd();
      if (rewarded) {
        await _persistUnlock(scenarioId);
        state = state.copyWith(isUnlocking: false);
        return true;
      }
      state = state.copyWith(isUnlocking: false, error: 'Ad not completed.');
      return false;
    } catch (e) {
      state = state.copyWith(isUnlocking: false, error: 'Failed: $e');
      return false;
    }
  }

  Future<bool> unlockWithPurchase(String scenarioId) async {
    state = state.copyWith(isUnlocking: true, error: null);
    try {
      final purchaseController = _ref.read(purchaseControllerProvider.notifier);
      await purchaseController.purchase('strategy_game_scenario_pack_1');
      await _persistUnlock(scenarioId);
      state = state.copyWith(isUnlocking: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUnlocking: false, error: 'Purchase failed: $e');
      return false;
    }
  }
}

final scenarioUnlockControllerProvider =
    StateNotifierProvider<ScenarioUnlockController, ScenarioUnlockState>((ref) {
      return ScenarioUnlockController(ref);
    });
