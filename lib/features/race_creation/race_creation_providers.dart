import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/race_model.dart';
import '../../models/worldview_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/game_config/game_config_providers.dart';
import '../splash/splash_providers.dart';
import '../auth/auth_providers.dart';
import '../world_setting/world_setting_providers.dart';

// The worldview the race is being created for.
//
// This used to read AppConstants.defaultWorldviewKey unconditionally, so no
// matter which world the player picked, race creation always offered the
// 1830 Fantasy stats (Strength/Wisdom/Technology/Magic/Artistry/Life) and saved
// the race with worldviewKey '1830_fantasy'. A Last Breath player could never
// put a point into Luck, and the Magic they were forced to spend on was not
// read by that world's judging at all.
final activeWorldviewProvider = Provider<WorldviewModel>((ref) {
  final config = ref.watch(gameConfigProvider);
  final selectedKey = ref.watch(selectedWorldviewKeyProvider);
  return config.worldviews[selectedKey] ??
      config.worldviews[AppConstants.defaultWorldviewKey] ??
      WorldviewModel.defaultWorldview();
});

// Race creation state
class RaceCreationState {
  final String raceName;
  final String overview;
  final Map<String, int> stats;
  final bool isSaving;
  final String? errorMessage;
  final bool isBossMode;

  const RaceCreationState({
    this.raceName = '',
    this.overview = '',
    required this.stats,
    this.isSaving = false,
    this.errorMessage,
    this.isBossMode = false,
  });

  int get maxPoints => isBossMode ? 999 : AppConstants.maxStatPoints;
  int get totalPoints => stats.values.fold(0, (s, v) => s + v);
  int get remainingPoints => maxPoints - totalPoints;
  bool get isValid =>
      raceName.trim().length >= AppConstants.minRaceNameLength &&
      totalPoints > 0 &&
      totalPoints <= maxPoints;

  RaceCreationState copyWith({
    String? raceName,
    String? overview,
    Map<String, int>? stats,
    bool? isSaving,
    String? errorMessage,
    bool? isBossMode,
  }) {
    return RaceCreationState(
      raceName: raceName ?? this.raceName,
      overview: overview ?? this.overview,
      stats: stats ?? this.stats,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isBossMode: isBossMode ?? this.isBossMode,
    );
  }
}

class RaceCreationController extends StateNotifier<RaceCreationState> {
  final Ref _ref;

  RaceCreationController(this._ref)
      : super(RaceCreationState(
          stats: _initialStats(_ref),
          isBossMode: _isBoss(_ref),
        ));

  static Map<String, int> _initialStats(Ref ref) {
    final worldview = ref.read(activeWorldviewProvider);
    return {for (final stat in worldview.stats) stat: 0};
  }

  static bool _isBoss(Ref ref) {
    final userAsync = ref.read(currentUserModelProvider);
    return userAsync.valueOrNull?.isBossEnabled ?? false;
  }

  void setRaceName(String name) {
    state = state.copyWith(raceName: name);
  }

  void setOverview(String text) {
    state = state.copyWith(overview: text);
  }

  void incrementStat(String stat) {
    if (state.remainingPoints <= 0) return;
    final current = state.stats[stat] ?? 0;
    if (!state.isBossMode && current >= 10) return;
    final newStats = Map<String, int>.from(state.stats);
    newStats[stat] = current + 1;
    state = state.copyWith(stats: newStats);
  }

  void decrementStat(String stat) {
    final current = state.stats[stat] ?? 0;
    if (current <= 0) return;
    final newStats = Map<String, int>.from(state.stats);
    newStats[stat] = current - 1;
    state = state.copyWith(stats: newStats);
  }

  void setStat(String stat, int value) {
    final current = state.stats[stat] ?? 0;
    final delta = value - current;
    if (delta > 0 && state.remainingPoints < delta) return;
    if (value < 0) return;
    final newStats = Map<String, int>.from(state.stats);
    newStats[stat] = value;
    state = state.copyWith(stats: newStats);
  }

  Future<bool> saveRace() async {
    if (!state.isValid) {
      state = state.copyWith(errorMessage: 'err_race_incomplete');
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final worldview = _ref.read(activeWorldviewProvider);
      final race = RaceModel.create(
        raceName: state.raceName.trim(),
        worldviewKey: worldview.worldviewKey,
        stats: Map<String, int>.from(state.stats),
        overview: state.overview.trim(),
      );

      final storageService = _ref.read(hiveStorageServiceProvider);
      await storageService.saveRace(race);
      _ref.invalidate(currentRaceProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'err_race_save_failed',
      );
      return false;
    }
  }

  void reset() {
    final worldview = _ref.read(activeWorldviewProvider);
    state = RaceCreationState(
      stats: {for (final stat in worldview.stats) stat: 0},
    );
  }
}

final raceCreationControllerProvider =
    StateNotifierProvider.autoDispose<RaceCreationController, RaceCreationState>((ref) {
  return RaceCreationController(ref);
});
