import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/battle_record_model.dart';
import '../../models/war_history_model.dart';
import '../splash/splash_providers.dart';
import '../settings/settings_providers.dart';
import '../auth/auth_providers.dart';
import '../world_setting/world_setting_providers.dart';
import 'scenario_title.dart';
import '../../services/game_config/game_config_providers.dart';

// Battle records provider
final battleRecordsProvider = FutureProvider<List<BattleRecordModel>>((ref) async {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return storageService.getBattleRecords();
});

// War histories provider
final warHistoriesProvider = FutureProvider<List<WarHistoryModel>>((ref) async {
  final storageService = ref.watch(hiveStorageServiceProvider);
  return storageService.getWarHistories();
});

// War history controller state
class WarHistoryControllerState {
  final bool isGenerating;
  final String? error;
  final String? generatedNarrative;

  const WarHistoryControllerState({
    this.isGenerating = false,
    this.error,
    this.generatedNarrative,
  });

  WarHistoryControllerState copyWith({
    bool? isGenerating,
    String? error,
    String? generatedNarrative,
  }) {
    return WarHistoryControllerState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      generatedNarrative: generatedNarrative ?? this.generatedNarrative,
    );
  }
}

class WarHistoryController extends StateNotifier<WarHistoryControllerState> {
  final Ref _ref;

  WarHistoryController(this._ref) : super(const WarHistoryControllerState());

  Future<bool> toggleFavorite(BattleRecordModel record) async {
    try {
      final storageService = _ref.read(hiveStorageServiceProvider);
      final updated = record.copyWith(isFavorite: !record.isFavorite);
      await storageService.updateBattleRecord(updated);
      _ref.invalidate(battleRecordsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.deleteBattleRecord(id);
      _ref.invalidate(battleRecordsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<WarHistoryModel?> generateWarChronicle(BattleRecordModel record) async {
    state = state.copyWith(isGenerating: true, error: null);
    try {
      final locale = _ref.read(localeProvider).languageCode;
      final race = _ref.read(currentRaceProvider);
      final config = _ref.read(gameConfigProvider);
      final scenario = config.scenarios[record.scenarioId];

      // Prefer the worldview stored with the battle. Falling back to the
      // currently selected world (not fantasy) only for legacy Hive rows.
      final worldviewKey = record.worldviewKey.isNotEmpty
          ? record.worldviewKey
          : (_ref.read(selectedWorldviewKeyProvider));

      final callable = FirebaseFunctions.instance.httpsCallable(
        'generateWarHistory',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call({
        'battleTitle': scenarioDisplayTitle(
          config: config,
          scenarioId: record.scenarioId,
          storedTitle: record.scenarioTitle,
          languageCode: locale,
        ),
        'playerStrategy': record.playerStrategy,
        'raceStats': record.playerStats,
        'raceName': race?.raceName ?? 'Unknown',
        'opponentName': scenario?.localizedEnemyName(locale) ?? '',
        'outcome': record.outcome,
        'scenarioId': record.scenarioId,
        'shortReport': record.aiReport.length > 200
            ? record.aiReport.substring(0, 200)
            : record.aiReport,
        'worldviewKey': worldviewKey,
        'locale': locale,
        if (record.survivalDays != null) 'survivalDays': record.survivalDays,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final narrative = data['chronicleText'] as String? ?? '';
      if (narrative.isEmpty) {
        state = state.copyWith(isGenerating: false, error: 'err_chronicle_failed');
        return null;
      }

      final history = WarHistoryModel(
        id: const Uuid().v4(),
        sourceRecordId: record.id,
        longNarrative: narrative,
        createdAt: DateTime.now(),
        sharedToX: false,
        title: scenarioDisplayTitle(
          config: config,
          scenarioId: record.scenarioId,
          storedTitle: record.scenarioTitle,
          languageCode: locale,
        ),
      );

      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.saveWarHistory(history);
      _ref.invalidate(warHistoriesProvider);
      _ref.invalidate(currentUserModelProvider);

      state = state.copyWith(isGenerating: false, generatedNarrative: narrative);
      return history;
    } on FirebaseFunctionsException catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: e.message?.contains('Not enough tickets') == true
            ? e.message
            : 'err_chronicle_failed',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'err_chronicle_failed');
      return null;
    }
  }
}

final warHistoryControllerProvider =
    StateNotifierProvider<WarHistoryController, WarHistoryControllerState>((ref) {
  return WarHistoryController(ref);
});

// Parchment image controller
class ParchmentImageController extends StateNotifier<bool> {
  ParchmentImageController() : super(false);

  void setLoading(bool loading) => state = loading;
}

final parchmentImageControllerProvider =
    StateNotifierProvider<ParchmentImageController, bool>((ref) {
  return ParchmentImageController();
});
