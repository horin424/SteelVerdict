import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pvp_match_model.dart';
import '../auth/auth_providers.dart';

// Active PvP matches
final activePvpMatchesProvider = FutureProvider<List<PvpMatchModel>>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];

  try {
    final firestoreService = ref.read(firestoreServiceProvider);
    return await firestoreService.getActivePvpMatches(user.uid);
  } catch (e) {
    return [];
  }
});

// PvP matchmaking controller
class PvpMatchmakingState {
  final bool isSearching;
  final String? error;
  final PvpMatchModel? createdMatch;

  const PvpMatchmakingState({
    this.isSearching = false,
    this.error,
    this.createdMatch,
  });

  PvpMatchmakingState copyWith({
    bool? isSearching,
    String? error,
    PvpMatchModel? createdMatch,
  }) {
    return PvpMatchmakingState(
      isSearching: isSearching ?? this.isSearching,
      error: error,
      createdMatch: createdMatch ?? this.createdMatch,
    );
  }
}

class PvpMatchmakingController extends StateNotifier<PvpMatchmakingState> {
  final Ref _ref;

  PvpMatchmakingController(this._ref) : super(const PvpMatchmakingState());

  Future<PvpMatchModel?> findOrCreateMatch() async {
    state = state.copyWith(isSearching: true, error: null);

    try {
      final authState = _ref.read(authStateChangesProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        state = state.copyWith(isSearching: false, error: 'Not signed in.');
        return null;
      }

      final race = _ref.read(currentRaceProvider);
      if (race == null) {
        state = state.copyWith(isSearching: false, error: 'Create a race first.');
        return null;
      }

      // Call Cloud Function — Admin SDK bypasses Firestore rules
      final callable = FirebaseFunctions.instance.httpsCallable(
        'findOrCreatePvpMatch',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({
        'raceName': race.raceName,
        'raceStats': race.stats,
      });

      final data = result.data as Map<String, dynamic>;
      final matchId = data['matchId'] as String;
      final isNewMatch = data['isNewMatch'] as bool;
      final now = DateTime.now();

      final match = PvpMatchModel(
        matchId: matchId,
        playerAUid: isNewMatch ? user.uid : (data['opponentUid'] as String? ?? ''),
        playerBUid: isNewMatch ? '' : user.uid,
        playerARaceName: isNewMatch ? race.raceName : (data['opponentRaceName'] as String? ?? ''),
        playerBRaceName: isNewMatch ? '' : race.raceName,
        playerAStats: isNewMatch ? race.stats : (Map<String, dynamic>.from(data['opponentStats'] as Map? ?? {}).map((k, v) => MapEntry(k, (v as num).toInt()))),
        playerBStats: isNewMatch ? {} : race.stats,
        playerAStrategy: '',
        playerBStrategy: '',
        shortReport: '',
        winner: '',
        status: isNewMatch ? PvpMatchStatus.waiting : PvpMatchStatus.active,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      );

      _ref.invalidate(activePvpMatchesProvider);
      state = state.copyWith(isSearching: false, createdMatch: match);
      return match;
    } catch (e) {
      state = state.copyWith(isSearching: false, error: 'Matchmaking failed: $e');
      return null;
    }
  }
}

final pvpMatchmakingControllerProvider =
    StateNotifierProvider<PvpMatchmakingController, PvpMatchmakingState>((ref) {
  return PvpMatchmakingController(ref);
});

// PvP battle controller
class PvpBattleState {
  final bool isSubmitting;
  final bool isSubmitted;
  final String? error;

  const PvpBattleState({
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.error,
  });

  PvpBattleState copyWith({
    bool? isSubmitting,
    bool? isSubmitted,
    String? error,
  }) {
    return PvpBattleState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      error: error,
    );
  }
}

class PvpBattleController extends StateNotifier<PvpBattleState> {
  final Ref _ref;

  PvpBattleController(this._ref) : super(const PvpBattleState());

  Future<bool> submitStrategy(String matchId, String strategy) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final authState = _ref.read(authStateChangesProvider);
      final user = authState.valueOrNull;
      if (user == null) {
        state = state.copyWith(isSubmitting: false, error: 'Not signed in.');
        return false;
      }

      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.submitPvpStrategy(matchId, user.uid, strategy);

      state = state.copyWith(isSubmitting: false, isSubmitted: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'Failed to submit: $e');
      return false;
    }
  }
}

final pvpBattleControllerProvider =
    StateNotifierProvider.autoDispose<PvpBattleController, PvpBattleState>((ref) {
  return PvpBattleController(ref);
});
