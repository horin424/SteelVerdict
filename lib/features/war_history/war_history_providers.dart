import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/battle_record_model.dart';
import '../../models/war_history_model.dart';
import '../../services/battle_api/battle_api_service.dart';
import '../splash/splash_providers.dart';
import '../battle/battle_providers.dart';
import '../settings/settings_providers.dart';

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
      // Use the battle API to generate a long narrative
      final battleApiService = _ref.read(battleApiServiceProvider);
      final locale = _ref.read(localeProvider).languageCode;
      final response = await battleApiService.submitBattle(
        BattleRequest(
          playerStrategy: record.playerStrategy,
          raceStats: record.playerStats,
          scenarioId: record.scenarioId,
          gameMode: 'epic', // Use epic mode for narrative generation
          modelChoice: ModelChoice.gemini,
          locale: locale,
        ),
      );

      final narrative = response.reportText;
      final history = WarHistoryModel(
        id: const Uuid().v4(),
        sourceRecordId: record.id,
        longNarrative: narrative,
        createdAt: DateTime.now(),
        sharedToX: false,
        title: 'The ${record.scenarioTitle.isNotEmpty ? record.scenarioTitle : record.scenarioId} Chronicle',
      );

      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.saveWarHistory(history);
      _ref.invalidate(warHistoriesProvider);

      state = state.copyWith(isGenerating: false, generatedNarrative: narrative);
      return history;
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: 'Failed to generate chronicle: $e');
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
