import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/features/race_creation/race_creation_providers.dart';
import 'package:strategy_game/models/worldview_model.dart';

/// Every player, Warlord too, builds a race of 30 points with at most 10 per
/// stat: what the server accepts (submitBattle.ts). Warlord could allocate 999,
/// and those battles failed. (Yoshimoto agreed, 14 Oct.)
void main() {
  const world = WorldviewModel(
    worldviewKey: 'test_world',
    title: 'Test',
    stats: ['a', 'b', 'c', 'd'],
    statDescriptions: {},
    commonJudgment: '',
    worldviewDescription: '',
  );

  late ProviderContainer container;
  late RaceCreationController controller;
  RaceCreationState state() => container.read(raceCreationControllerProvider);

  setUp(() {
    container = ProviderContainer(overrides: [activeWorldviewProvider.overrideWithValue(world)]);
    // autoDispose: keep it alive for the test.
    container.listen(raceCreationControllerProvider, (_, __) {});
    controller = container.read(raceCreationControllerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('30 points in total', () {
    expect(state().maxPoints, AppConstants.maxStatPoints);
    expect(state().maxPoints, 30);
  });

  test('a stat stops at 10', () {
    for (var i = 0; i < 12; i++) {
      controller.incrementStat('a');
    }
    expect(state().stats['a'], 10);
  });

  test('setting a stat above 10 is refused', () {
    controller.setStat('a', 11);
    expect(state().stats['a'], 0);
    controller.setStat('a', 10);
    expect(state().stats['a'], 10);
  });

  test('no point beyond 30', () {
    for (final s in ['a', 'b', 'c']) {
      controller.setStat(s, 10);
    }
    expect(state().totalPoints, 30);
    controller.incrementStat('d');
    expect(state().stats['d'], 0);
    expect(state().remainingPoints, 0);
  });
}
