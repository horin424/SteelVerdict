import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/battle_record_model.dart';
import '../../services/battle_api/battle_api_service.dart';
import '../../services/battle_api/cloud_functions_battle_service.dart';
import '../auth/auth_providers.dart';
import '../splash/splash_providers.dart';
import '../home/home_providers.dart';
import '../game_mode_selection/game_mode_providers.dart';
import '../settings/settings_providers.dart';


// Battle API service provider
final battleApiServiceProvider = Provider<BattleApiService>((ref) {
  return CloudFunctionsBattleService();
});

// Practice play count provider
final practicePlayCountProvider = StateProvider<int>((ref) => 0);

// Battle result provider (holds the last result)
final battleResultProvider = StateProvider<BattleResponse?>((ref) => null);

// Battle controller state
class BattleControllerState {
  final bool isSubmitting;
  final String? errorMessage;
  final BattleResponse? result;
  final int strategyCharCount;
  final bool showAdChoice; // true when practice ad is due — show watch/skip choice

  const BattleControllerState({
    this.isSubmitting = false,
    this.errorMessage,
    this.result,
    this.strategyCharCount = 0,
    this.showAdChoice = false,
  });

  BattleControllerState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    BattleResponse? result,
    int? strategyCharCount,
    bool? showAdChoice,
  }) {
    return BattleControllerState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      result: result ?? this.result,
      strategyCharCount: strategyCharCount ?? this.strategyCharCount,
      showAdChoice: showAdChoice ?? this.showAdChoice,
    );
  }
}

class BattleController extends StateNotifier<BattleControllerState> {
  final Ref _ref;

  BattleController(this._ref) : super(const BattleControllerState());

  void updateCharCount(int count) {
    state = state.copyWith(strategyCharCount: count);
  }

  // Called by the UI when user picks "Watch Ad" during practice ad prompt
  Future<void> watchPracticeAd() async {
    state = state.copyWith(showAdChoice: false);
    try {
      final adService = _ref.read(adServiceProvider);
      await adService.loadInterstitialAd();
      await adService.showInterstitialAd();
    } catch (_) {}
  }

  // Called by the UI when user picks "Skip (-1 ticket)" during practice ad prompt
  Future<void> skipPracticeAd() async {
    state = state.copyWith(showAdChoice: false);
    try {
      await FirebaseFunctions.instance.httpsCallable('skipAd').call();
      _ref.invalidate(currentUserModelProvider);
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        state = state.copyWith(errorMessage: 'Not enough tickets to skip.');
        // Show ad anyway since they can't skip
        try {
          final adService = _ref.read(adServiceProvider);
          await adService.loadInterstitialAd();
          await adService.showInterstitialAd();
        } catch (_) {}
      }
    }
  }

  // Called by tabletop overlay skip button
  Future<bool> skipTabletopAd() async {
    try {
      await FirebaseFunctions.instance.httpsCallable('skipAd').call();
      _ref.invalidate(currentUserModelProvider);
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        state = state.copyWith(errorMessage: 'Not enough tickets to skip.');
      }
      return false;
    }
  }

  Future<BattleResponse?> submitBattle({
    required String scenarioId,
    required String gameMode,
    required String strategy,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null, showAdChoice: false);

    try {
      final race = _ref.read(currentRaceProvider);
      if (race == null) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'No race found. Please create a race first.',
        );
        return null;
      }

      // Check ticket cost — use effective cost (accounts for model choice)
      final cost = _ref.read(effectiveTicketCostProvider);
      final isFreeMode = gameMode == 'practice' || gameMode == 'tabletop' || gameMode == 'history_puzzle';

      if (!isFreeMode && cost > 0) {
        final userModel = await _ref.read(currentUserModelProvider.future);
        if (userModel != null && userModel.ticketCount < cost) {
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: 'Not enough tickets. You need $cost ticket(s).',
          );
          return null;
        }
      }

      // For practice mode: show ad choice every 3rd play
      if (gameMode == 'practice') {
        final playCount = _ref.read(practicePlayCountProvider);
        final newCount = playCount + 1;
        _ref.read(practicePlayCountProvider.notifier).state = newCount;
        if (newCount % 3 == 0) {
          // Signal UI to show Watch Ad / Skip choice
          state = state.copyWith(isSubmitting: false, showAdChoice: true);
          return null; // Battle will resume after user makes a choice
        }
      }

      final selectedModel = _ref.read(selectedModelProvider);
      final selectedWorldview = _ref.read(selectedWorldviewKeyProvider);
      final locale = _ref.read(localeProvider).languageCode;
      final request = BattleRequest(
        playerStrategy: strategy,
        raceStats: race.stats,
        scenarioId: scenarioId,
        gameMode: gameMode,
        modelChoice: selectedModel,
        raceName: race.raceName,
        worldviewKey: selectedWorldview,
        locale: locale,
      );

      final battleApiService = _ref.read(battleApiServiceProvider);
      final response = await battleApiService.submitBattle(request);

      // Save to local storage if not practice
      if (gameMode != 'practice') {
        await _saveBattleRecord(
          scenarioId: scenarioId,
          gameMode: gameMode,
          strategy: strategy,
          response: response,
          raceStats: race.stats,
        );
      }

      // Update personal best for history_puzzle
      if (gameMode == 'history_puzzle') {
        _updatePersonalBest(scenarioId, response.outcome);
      }

      // Log analytics
      final analytics = _ref.read(analyticsServiceProvider);
      await analytics.logBattleCompleted(
        mode: gameMode,
        scenarioId: scenarioId,
        outcome: response.outcome,
      );

      // Refresh ticket count (Cloud Function deducted server-side)
      _ref.invalidate(currentUserModelProvider);

      state = state.copyWith(isSubmitting: false, result: response);
      _ref.read(battleResultProvider.notifier).state = response;
      return response;
    } on FirebaseFunctionsException catch (e) {
      final msg = e.message ?? '';
      final String errorMessage;
      if (msg.contains('CONTENT_FILTER_BLOCKED')) {
        errorMessage = 'content_filter_blocked';
      } else if (msg.contains('Not enough tickets')) {
        errorMessage = msg;
      } else if (msg.contains('Authentication')) {
        errorMessage = 'battle_sign_in_required';
      } else {
        errorMessage = 'battle_failed_retry';
      }
      state = state.copyWith(isSubmitting: false, errorMessage: errorMessage);
      return null;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'battle_failed_retry');
      return null;
    }
  }

  void _updatePersonalBest(String scenarioId, String outcome) {
    try {
      final storage = _ref.read(hiveStorageServiceProvider);
      final key = 'pb_$scenarioId';
      final raw = storage.getSetting(key, defaultValue: null);
      int wins = 0, total = 0;
      if (raw != null) {
        final map = jsonDecode(raw as String) as Map<String, dynamic>;
        wins = (map['wins'] as int?) ?? 0;
        total = (map['total'] as int?) ?? 0;
      }
      total += 1;
      if (outcome == 'win') wins += 1;
      storage.saveSetting(key, jsonEncode({'wins': wins, 'total': total}));
    } catch (_) {}
  }

  Future<void> _saveBattleRecord({
    required String scenarioId,
    required String gameMode,
    required String strategy,
    required BattleResponse response,
    required Map<String, int> raceStats,
  }) async {
    try {
      final record = BattleRecordModel(
        id: const Uuid().v4(),
        scenarioId: scenarioId,
        gameMode: gameMode,
        playerStrategy: strategy,
        aiReport: response.reportText,
        playerStats: raceStats,
        outcome: response.outcome,
        createdAt: DateTime.now(),
        isFavorite: false,
        scenarioTitle: scenarioId,
      );

      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.saveBattleRecord(record);
    } catch (e) {
      // Non-fatal - battle still completed
    }
  }
}

final battleControllerProvider =
    StateNotifierProvider.autoDispose<BattleController, BattleControllerState>((ref) {
  return BattleController(ref);
});
