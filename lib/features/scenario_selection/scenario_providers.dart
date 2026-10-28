import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/scenario_model.dart';
import '../../services/game_config/game_config_providers.dart';
import '../../services/purchase/iap_purchase_service.dart';
import '../../services/purchase/purchase_service.dart';
import '../auth/auth_providers.dart';
import '../splash/splash_providers.dart';
import '../home/home_providers.dart';
import '../shop/shop_providers.dart';

const _kUnlockedKey = 'unlocked_scenarios';

/// How many scenarios the scenario pack unlocks (server: PACK_SIZE).
const kScenarioPackSize = 5;

/// Scenarios unlocked on this phone with an ad. They are not saved to the
/// account, so a reinstall loses them; the pack's choice is saved there.
Set<String> _localUnlockedIds(Ref ref) {
  final storage = ref.watch(hiveStorageServiceProvider);
  final raw = storage.getSetting(_kUnlockedKey, defaultValue: '[]') as String;
  return Set<String>.from(jsonDecode(raw) as List);
}

// All scenarios from Firestore game config, merged with the scenarios unlocked
// on this phone (ads) and the ones chosen with the scenario pack (account).
final scenariosProvider = Provider<List<ScenarioModel>>((ref) {
  final gameConfig = ref.watch(gameConfigProvider);
  final localIds = _localUnlockedIds(ref);
  final packIds = ref.watch(currentUserModelProvider).valueOrNull?.packUnlockedScenarioIds ??
      const <String>{};

  return gameConfig.scenarios.values.map((s) {
    final unlocked = localIds.contains(s.scenarioId) || packIds.contains(s.scenarioId);
    return unlocked ? s.copyWith(isUnlocked: true) : s;
  }).toList()..sort((a, b) => a.difficulty.compareTo(b.difficulty));
});

/// What the scenario pack can choose from: every scenario the game config
/// locks (not free, not unlocked for everyone), the same set the server
/// accepts. A scenario unlocked with an ad stays in the list, since only
/// choosing it keeps it after a reinstall.
class PackChoice {
  final ScenarioModel scenario;

  /// Unlocked on this phone with an ad.
  final bool unlockedHere;

  const PackChoice(this.scenario, {required this.unlockedHere});
}

final packChoicesProvider = Provider<List<PackChoice>>((ref) {
  final gameConfig = ref.watch(gameConfigProvider);
  final localIds = _localUnlockedIds(ref);
  return gameConfig.scenarios.values
      .where((s) => !s.isFree && !s.isUnlocked)
      .map((s) => PackChoice(s, unlockedHere: localIds.contains(s.scenarioId)))
      .toList()
    ..sort((a, b) {
      final byWorld = a.scenario.worldviewKey.compareTo(b.scenario.worldviewKey);
      return byWorld != 0 ? byWorld : a.scenario.difficulty.compareTo(b.scenario.difficulty);
    });
});

/// How many scenarios the choice must have: the pack's size, or all of them
/// when fewer are locked (the server checks the same).
int packChoiceCount(int lockedCount) =>
    lockedCount < kScenarioPackSize ? lockedCount : kScenarioPackSize;

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
      state = state.copyWith(isUnlocking: false, error: 'err_ad_not_completed');
      return false;
    } catch (e) {
      state = state.copyWith(isUnlocking: false, error: 'err_unlock_failed');
      return false;
    }
  }

  /// Buys the scenario pack and completes with what happened. Nothing is
  /// unlocked here: once the server has granted the pack, the player chooses
  /// its scenarios (choosePackScenarios). Unlocking at the store's sheet used
  /// to happen even when the user then cancelled.
  Future<PurchaseOutcome> buyScenarioPack() async {
    state = state.copyWith(isUnlocking: true, error: null);
    final purchaseController = _ref.read(purchaseControllerProvider.notifier);
    final outcome = await purchaseController.purchase(ProductIds.scenarioPack1);
    state = state.copyWith(isUnlocking: false);
    return outcome;
  }

  /// Saves the scenarios chosen with the pack to the account (final). True
  /// when saved; otherwise [ScenarioUnlockState.error] says why.
  Future<bool> choosePackScenarios(List<String> scenarioIds) async {
    state = state.copyWith(isUnlocking: true, error: null);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('chooseScenarioPack')
          .call({'scenarioIds': scenarioIds});
      _ref.invalidate(currentUserModelProvider);
      _ref.invalidate(scenariosProvider);
      state = state.copyWith(isUnlocking: false);
      return true;
    } on FirebaseFunctionsException catch (e) {
      // The account already has a choice: show it rather than an error alone.
      if (e.code == 'already-exists') _ref.invalidate(currentUserModelProvider);
      state = state.copyWith(isUnlocking: false, error: packChoiceError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isUnlocking: false, error: 'err_pack_choice_failed');
      return false;
    }
  }
}

/// The error code to show when the server refuses a pack choice.
String packChoiceError(String functionsCode) {
  switch (functionsCode) {
    case 'already-exists':
      return 'err_pack_already_chosen';
    case 'failed-precondition':
      return 'err_pack_not_owned';
    default:
      return 'err_pack_choice_failed';
  }
}

final scenarioUnlockControllerProvider =
    StateNotifierProvider<ScenarioUnlockController, ScenarioUnlockState>((ref) {
      return ScenarioUnlockController(ref);
    });
