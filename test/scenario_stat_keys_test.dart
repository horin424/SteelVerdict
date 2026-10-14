import 'package:flutter_test/flutter_test.dart';
import 'package:strategy_game/core/constants/app_constants.dart';
import 'package:strategy_game/features/admin/scenario_stat_keys.dart';
import 'package:strategy_game/models/worldview_model.dart';

/// The app's scenario editor gives enemies the world's stats, like the PC
/// admin (it used the legacy strength … life list for every world).
void main() {
  WorldviewModel world(String key, List<String> stats) => WorldviewModel(
        worldviewKey: key,
        title: key,
        stats: stats,
        statDescriptions: const {},
        commonJudgment: '',
        worldviewDescription: '',
      );

  final worlds = {
    AppConstants.defaultWorldviewKey: world(AppConstants.defaultWorldviewKey, ['剣', '魔', '盾']),
    'aces_high': world('aces_high', ['speed', 'firepower', 'armor']),
    'empty_world': world('empty_world', []),
  };

  group('defaultStatKeys', () {
    test("a world's own stats", () {
      expect(defaultStatKeys(worlds, 'aces_high'), ['speed', 'firepower', 'armor']);
    });
    test('a world without stats gets the default world\'s', () {
      expect(defaultStatKeys(worlds, 'empty_world'), ['剣', '魔', '盾']);
    });
    test('an unknown world gets the default world\'s', () {
      expect(defaultStatKeys(worlds, 'missing'), ['剣', '魔', '盾']);
    });
    test('the legacy list only when no world has any', () {
      expect(defaultStatKeys(const {}, 'missing'), legacyStatKeys);
    });
  });

  group('orderedStatKeys', () {
    test("in the world's order, then others alphabetically", () {
      expect(
        orderedStatKeys(['zeal', 'armor', 'speed', 'alpha', 'firepower'], ['speed', 'firepower', 'armor']),
        ['speed', 'firepower', 'armor', 'alpha', 'zeal'],
      );
    });
    test("keeps only the scenario's keys", () {
      expect(orderedStatKeys(['armor'], ['speed', 'firepower', 'armor']), ['armor']);
    });
  });
}
